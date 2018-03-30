signature TRANSLATE = sig
    
    type level
    type access (* not the same as Frame.access *)
    type exp

    val outermost: level
    val newLevel: {parent: level, name: Temp.label, formals: bool list} -> level
    val formals: level -> access list
    val allocLocal: level -> bool -> access
end

structure Translate : TRANSLATE =
struct

    structure Frame : FRAME = MipsFrame

    structure T = Tree
    
    datatype exp = Ex of T.exp
                 | Nx of T.stm
                 | Cx of Temp.label * Temp.label -> T.stm

    datatype level = Top
                   | Level of {parent: level, frame: Frame.frame, count: unit ref}

    type access = level * Frame.access

    val outermost = Top

    fun newLevel {parent, name, formals} = 
        Level {parent = parent,
               frame = Frame.newFrame {name = name, formals = true::formals},
               count = ref()}

    fun formals level = 
        case level of
            Top => []
          | _ =>
                List.tl (List.map (fn f => (level, f)) (Frame.getFormals (#frame level)))

    fun allocLocal level escape = 
        case level of
            Top => ErrorMsg.impossible "Allocation of local varible at Top level"
          | _ => (level, Frame.allocLocal (#frame level) escape)

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
      | unCx(Ex e) = (fn (t, f) => T.CJUMP(T.NE, e, T.CONST 0, t, f)
      | unCx(Ex (T.CONST 0)) = (fn(t,f) => JUMP(T.NAME f, [f])
      | unCx(Ex (T.CONST 1)) = (fn(t,f) => JUMP(T.NAME t, [t])
      | unCx(Nx _) = ErrorMsg.impossible "unCx cannot get Nx"

    fun unNx(Nx n) = n
      | unNx(Ex e) = T.EXP e
      | unNx(Cx c) = 
            let val t = Temp.newlabel() and f = Temp.newlabel ()
            in seq[c(t,f),
                   T.LABEL t,
                   T.LEBEL f]
            end

    fun nilexp = Ex(T.CONST(0))

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
	   | SOME(F.STRING(lbl,_)) => Ex(T.NAME(lab)) (* find same string, reuse it *)
    end
    
    fun call (_,Lev({parent=Top,...},_),label,exps,isProc) : exp = 
	    if isProc
	    then Nx(T.EXP(F.externalCall(Symbol.name label,map unEx exps)))
	    else Ex(F.externalCall(Symbol.name label,map unEx exps))
	(* if is externalcall *) 
	  | call (uselevel,deflevel,label,exps,isprocedure) : exp =
	    let
	      fun depth level =
	            case level of
	              Top => 0
	            | Lev({parent,...},_) => 1 + depth(parent)
	      val diff = depth uselevel - depth deflevel + 1 
	      fun getStaticLink (diff,level) =
	          if diff = 0 then T.TEMP Frame.FP
	          else
	            let val Lev({parent,frame},_) = level in
	              Frame.getData(hd(Frame.getFormals frame))(getStaticLink(diff-1,parent))
	              (* get the static link of one level up *)
	            end
	      val ans = T.CALL(T.NAME label,(getStaticLink(diff,uselevel)) :: (map unEx exps))
	      (* get the static of of parrent and add it to the start of args *)
	    in if isProc
	       then Nx(T.EXP(ans)) else Ex(ans)
    end
    
    

    fun binop (l, op, r) =
        let val left = unEx(l)
            val right = unEx(r)
            val bop = case op of
                            Abysn.PlusOp => T.PLUS
                          | Abysn.MinusOp => T.MINUS
                          | Abysn.TimesOp => T.MUL
                          | Abysn.DivideOp => T.DIV
        in Ex(T.BINOP(bop, left, right))
        end

    fun relop (l, op, r) =
        let val left = unEx(e1)
            val right = unEx(e2)
                val rop = case oper of Abysn.EqOp => T.EQ
                                     | Abysn.NeqOp => T.NE
                                     | Abysn.LtOp => T.LT
                                     | Abysn.LeOp => T.LE
                                     | Abysn.GtOp => T.GT
                                     | Abysn.GeOp => T.GE
        in Cx((fn (t,f) => T.CJUMP(treeop, left, right, t, f))) 
        end

    fun simpleVar (varaccess, curlevel) =
        let val (Level varlevel, varacc) = varaccess
            fun iter (currentlevel, acc) =
                if (#count varlevel = #count currentlevel) 
                then Frame.getData(varacc)(acc)
                else 
                    let val staticlink = hd(Frame.getFormals #frame currentlevel)
                    in iter(#parent currentlevel, Frame.getData(staticlink)(acc))
                    end
        in Ex(iter(curlevel,T.TEMP(Frame.FP))) 
        end

    fun subscriptVar (arrayexp, subscriptexp)=
        Ex(T.MEM(T.BINOP(T.PLUS,unEx(arrayexp),T.BINOP(T.MUL,unEx(subscriptexp),T.CONST(Frame.wordSize)))))

    fun fieldVar (recordexp, fieldnumber) =
        Ex(T.MEM(T.BINOP(T.PLUS,unEx(recordexp), T.CONST(fieldnumber*Frame.wordSize))))

    fun ifexp(testexp, thenexp, elseexp: exp option): exp = 
        let val condFn = unCx testexp
            val thenExp = unEx thenexp
            val elseExp = if isSome elseexp then SOME(unEx valOf(elseexp)) else NONE
            val tlabel = Temp.newlabel()
            val flabel = Temp.newlabel()
            val ans = Temp.newtemp()
            val endlabel = Temp.newlabel()
        in if isSome(elseExp) then
           ESEQ(seq[condFn(tlabel,flabel),
                T.LABEL tlabel,
                T.MOVE(T.TEMP ans,thanExp),
                JUMP(T.NAME(endlabel),[endlabel]),
                T.LABEL flabel
                T.MOVE(T.TEMP ans, valOf (elseExp)),
                T.LABEL endlabel,
                ],T.TEMP ans)
          else 
            ESEQ(seq[condFn(tlabel,flabel),
              T.LABEL tlabel,
              T.MOVE(T.TEMP ans,thanExp),
              JUMP(T.NAME(endlabel),[endlabel]),
              T.LABEL flabel
              T.MOVE(T.TEMP ans, T.CONST 0),
              T.LABEL endlabel,
                ],T.TEMP ans)
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
    | sequence (exps) = let val restexp = seq(map unNx (List.take(exps,length(exps)-1))      
    						val lastexp = List.last(exps) in
    					    case lastexp of
                                 Nx(s) => Nx(T.SEQ(restexp,s))
           				       | _ => Ex(T.ESEQ(restexp,unEx(last)))
        			    end
        			   
    
   fun letexp(decs,body) = 
       case decs of 
         [] => unEx(body)
         decs => Ex(T.ESEQ(seq (map unNx decs),unEx(body)))


   end









   

  

 
 
 
 