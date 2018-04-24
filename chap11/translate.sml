signature TRANSLATE = sig
    
    type level
    type access (* not the same as Frame.access *)
    type exp
    type frag

    val outermost: level
    val newLevel: {parent: level, name: Temp.label, formals: bool list} -> level
    val formals: level -> access list
    val allocLocal: level -> bool -> access
    val procEntryExit: level * exp -> unit
    val assign : exp * exp -> exp
    val simpleVar : access * level -> exp
    val fieldVar : exp * int -> exp
    val subscriptVar : exp * exp -> exp
    val relop : exp * Absyn.oper * exp -> exp
    val binop : exp * Absyn.oper *  exp -> exp
    val nilexp : exp
    val letexp : exp list * exp -> exp
    val intexp : int -> exp
    val strexp : string -> exp
    val recordExp : exp list -> exp
    val sequence : exp list -> exp
    val ifexp : exp * exp * exp option -> exp
    val loop : exp * exp * Temp.label -> exp
    val break : Temp.label -> exp
    val array : exp * exp -> exp
    val call : level * level * Temp.label * exp list * bool -> exp
    val errorexp: exp
    val reset : unit -> unit
    val getResult : unit -> frag list
end

structure Translate : TRANSLATE =
struct

    structure F : FRAME = Frame

    structure T = Tree
    
    datatype exp = Ex of T.exp
                 | Nx of T.stm
                 | Cx of Temp.label * Temp.label -> T.stm

    datatype level = Top
                   | Level of {parent: level, frame: Frame.frame, count: unit ref}


    type access = level * Frame.access
    type frag = F.frag
    
    val errorexp = Ex(T.CONST 0)
    val outermost = Top

    val fragments : frag list ref = ref nil

    fun reset () = fragments := nil

    fun getResult () = !fragments

    fun newLevel {parent, name, formals} = 
        Level {parent = parent,
               frame = Frame.newFrame {name = name, formals = true::formals},
               count = ref()}

    fun formals level = 
        case level of
            Top => []
           | Level {parent=parent,frame=frame,...}  =>
               let val formals = tl (Frame.formals frame) in
      (map (fn (x) => (level,x)) formals) end

    fun allocLocal (level:level) escape = 
        case level of
            Top => ErrorMsg.impossible "Allocation of local varible at Top level"
          | Level{parent,frame,count} => (level, Frame.allocLocal (frame) escape)

    fun seq stms = 
        case stms of
            [] => T.EXP(T.CONST 0)
          | [stm] => stm
          | stm :: stm_s => T.SEQ(stm, seq stm_s)

    fun unEx (Ex e) = e
      | unEx (Cx c) = 
            let val r = Temp.newtemp()
                val t = Temp.newlabel() and f = Temp.newlabel()
            in  T.ESEQ(seq[T.MOVE(T.TEMP r, T.CONST 1),
                           c(t, f), 
                           T.LABEL f,
                           T.MOVE(T.TEMP r, T.CONST 0),
                           T.LABEL t], T.TEMP r)
            end
      | unEx (Nx n) = T.ESEQ(n, T.CONST 0)

    fun unCx(Cx c) = c
      | unCx(Ex (T.CONST 0)) = (fn(t,f) => T.JUMP(T.NAME f, [f]))
      | unCx(Ex (T.CONST 1)) = (fn(t,f) => T.JUMP(T.NAME t, [t]))
      | unCx(Ex e) = (fn (t, f) => T.CJUMP(T.NE, e, T.CONST 0, t, f))
      | unCx(Nx _) = ErrorMsg.impossible "unCx cannot get Nx"

    fun unNx(Nx n) = n
      | unNx(Ex e) = T.EXP e
      | unNx(Cx c) = 
            let val t = Temp.newlabel() and f = Temp.newlabel ()
            in seq[c(t,f),
                   T.LABEL t,
                   T.LABEL f]
            end

    val nilexp = Ex(T.CONST(0))

    fun intexp i = Ex(T.CONST(i))


    fun strexp s  =
	  let val t = List.find
	      (fn (x) =>
	          case x of
	            F.STRING(_,s') => s = s'
	          | _ => false) (!fragments)
	   (* try to find already same string and reuse it *)
	  in case t of
	     NONE => let val nlbl = Temp.newlabel() in
	         (fragments := F.STRING(nlbl,s) :: !fragments; Ex(T.NAME(nlbl))) end
	         (*find nothing, create one *)
	   | SOME(F.STRING(lbl,_)) => Ex(T.NAME(lbl)) (* find same string, reuse it *)
    end
    
    fun call (_,Level{parent=Top,...},label,exps,isProc) : exp = 
	    if isProc
	    then Nx(T.EXP(F.externalCall(Symbol.name label,map unEx exps)))
	    else Ex(F.externalCall(Symbol.name label,map unEx exps))
	(* if is externalcall *) 
	  | call (uselevel,deflevel,label,exps,isProc) : exp =
	    let
	      fun depth level =
	            case level of
	              Top => 0
	            | Level{parent,...} => 1 + depth(parent)
	      val diff = depth uselevel - depth deflevel + 1 
	      fun getStaticLink (diff,level) =
	          if diff = 0 then T.TEMP Frame.FP
	          else
	            let val Level{parent,frame,...} = level in
	              Frame.exp(hd(Frame.formals frame))(getStaticLink(diff-1,parent))
	              (* get the static link of one level up *)
	            end
	      val ans = T.CALL(T.NAME label,(getStaticLink(diff,uselevel)) :: (map unEx exps))
	      (* get the static of of parrent and add it to the start of args *)
	    in if isProc
	       then Nx(T.EXP(ans)) else Ex(ans)
    end

    fun binop (l, oper, r) =
        let val left = unEx(l)
            val right = unEx(r)
            val bop = case oper of
                            Absyn.PlusOp => T.PLUS
                          | Absyn.MinusOp => T.MINUS
                          | Absyn.TimesOp => T.MUL
                          | Absyn.DivideOp => T.DIV
        in Ex(T.BINOP(bop, left, right))
        end

    fun relop (e1, oper, e2) =
        let val left = unEx(e1)
            val right = unEx(e2)
                val rop = case oper of Absyn.EqOp => T.EQ
                                     | Absyn.NeqOp => T.NE
                                     | Absyn.LtOp => T.LT
                                     | Absyn.LeOp => T.LE
                                     | Absyn.GtOp => T.GT
                                     | Absyn.GeOp => T.GE
        in Cx((fn (t,f) => T.CJUMP(rop, left, right, t, f))) 
        end

    fun simpleVar (varaccess, currentlevel as Level{parent=cparent,count=ccount,frame=cframe}) =
        let val (Level varlevel, varacc) = varaccess
            fun iter (currentlevel, acc) =
                if (#count varlevel = ccount) 
                then Frame.exp(varacc)(acc)
                else 
                    let val staticlink = hd(Frame.formals cframe)
                    in iter(cparent, Frame.exp(staticlink)(acc))
                    end
        in Ex(iter(currentlevel,T.TEMP(Frame.FP))) 
        end

    fun subscriptVar (arrayexp, subscriptexp)=
        Ex(T.MEM(T.BINOP(T.PLUS,unEx(arrayexp),T.BINOP(T.MUL,unEx(subscriptexp),T.CONST(Frame.wordSize)))))

    fun fieldVar (recordexp, fieldnumber) =
        Ex(T.MEM(T.BINOP(T.PLUS,unEx(recordexp), T.CONST(fieldnumber*Frame.wordSize))))

    fun ifexp(testexp, thenexp, elseexp: exp option)= 
        let val condFn = unCx testexp
            val thenExp = unEx thenexp
            val elseExp = if isSome elseexp then SOME(unEx (valOf(elseexp))) else NONE
            val tlabel = Temp.newlabel()
            val flabel = Temp.newlabel()
            val ans = Temp.newtemp()
            val endlabel = Temp.newlabel()
        in if isSome(elseExp) then
          Ex( T.ESEQ(seq[condFn(tlabel,flabel),
                T.LABEL tlabel,
                T.MOVE(T.TEMP ans,thenExp),
                T.JUMP(T.NAME(endlabel),[endlabel]),
                T.LABEL flabel,
                T.MOVE(T.TEMP ans, valOf (elseExp)),
                T.LABEL endlabel
                ],T.TEMP ans))
         else 
            Ex(T.ESEQ(seq[condFn(tlabel,flabel),
              T.LABEL tlabel,
              T.MOVE(T.TEMP ans,thenExp),
              T.JUMP(T.NAME(endlabel),[endlabel]),
              T.LABEL flabel,
              T.MOVE(T.TEMP ans, T.CONST 0),
              T.LABEL endlabel
                ],T.TEMP ans))
        end

    fun recordExp fieldExps =
        let
            val r = Temp.newtemp ()
            fun indexedmap f items =
                let fun run (acc, l) = 
                    case l of [] => []
                       | x :: xs => f (acc, x) :: run (acc + 1, xs)
                in run (0, items)
                end
            val fieldTrees = seq(indexedmap(fn (i, x)=>T.MOVE(T.MEM(T.BINOP (T.PLUS, T.CONST (i * Frame.wordSize), T.TEMP r)), unEx x)) fieldExps)
        in 
            Ex (T.ESEQ(seq[T.MOVE(T.TEMP r, Frame.externalCall("allocRecord", [ T.CONST(List.length fieldExps * Frame.wordSize) ])), fieldTrees], T.TEMP r))
        end

    fun array (size, init) : exp =
         Ex(F.externalCall("initArray", [unEx(size),unEx(init)]))

    fun assign (left,right) : exp =
         Nx(T.MOVE(unEx(left),unEx(right)))

    fun loop (test, body, done_label) =
          let val test_label = Temp.newlabel()
           val body_label = Temp.newlabel() in
           Nx(seq[
           T.LABEL test_label,
           T.CJUMP(T.EQ,unEx(test),T.CONST 0, done_label, body_label),
           T.LABEL body_label,
           unNx(body),
           T.JUMP(T.NAME test_label, [test_label]),
           T.LABEL done_label])
           end

    fun break (label) : exp = Nx(T.JUMP(T.NAME label, [label]))

  
  fun sequence ([]) = Nx(T.EXP(T.CONST 0))
    | sequence ([exp]) = exp
    | sequence (exps) = 
                let 
                val restexp = seq(map unNx (List.take(exps,length(exps)-1)))      
    						val lastexp = List.last(exps) in
    					    case lastexp of
                                 Nx(s) => Nx(T.SEQ(restexp,s))
           				       | _ => Ex(T.ESEQ(restexp,unEx(lastexp)))
        			    end
        			   
    
   fun letexp(decs,body) = 
       case decs of 
         [] => Ex(unEx(body))
      | decs => Ex(T.ESEQ(seq (map unNx decs),unEx(body)))


fun procEntryExit (Level({frame,...}),body) =
    
    let val body' =
            Frame.procEntryExit1(frame,T.MOVE(T.TEMP Frame.RV,unEx(body)))
    in fragments := Frame.PROC{frame=frame,body=body'} :: !fragments
    end
    
end









   

  

 
 
 
 