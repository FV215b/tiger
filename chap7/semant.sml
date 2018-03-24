structure Semant: 
sig
    type expty
    type venv
    type tenv
    
    val transProg: Absyn.exp -> unit 
end = 

struct
    structure A = Absyn
    structure T = Types
    structure S = Symbol
    structure E = Env
    structure Tr = Translate

    type expty =  {exp:Tr.exp, ty: T.ty}
    
    type venv = Env.enventry Symbol.table
    type tenv = Env.ty Symbol.table

    val err = ErrorMsg.error
    
    fun checkdup (nil,nil) = ()
	  | checkdup (n::nr, p::pr) =
	    (if (List.all (fn (x) => (n <> x)) nr) then checkdup(nr,pr)
            else err p ("duplicated definition: " ^ S.name n))
          | checkdup (_,_) = ()

    fun type2string (ty:T.ty) = 
          case ty of 
		      T.NIL => "nil"
		    | T.UNIT => "unit"
			| T.INT => "int"
			| T.STRING => "string"
			| T.ARRAY(t,_) => "array of " ^ type2string(t)
			| T.NAME(sym,_) => "name of " ^ S.name(sym)
    		| T.RECORD(_,_) => "record"
      		     
    
    fun actual_ty (ty:T.ty,pos) =
	      case ty of
	        T.NAME(sym,tyref) =>
	        (case (!tyref) of
	           NONE => (err pos ("type undefined: " ^ S.name(sym)); T.NIL)
	         | SOME(ty) => actual_ty (ty,pos))
	      | T.ARRAY(t,u) => T.ARRAY(actual_ty(t,pos),u)
	    | _ => ty

    fun checkTypeSame (exp:T.ty, typ:T.ty, pos) =
	    let val aexp = actual_ty(exp,pos) in
	      if (aexp <> typ) then
	        case (aexp,typ) of
	          (T.NIL,T.RECORD(_,_)) => ()
	        | (_,_) =>  err pos ("expected " ^ type2string(typ) ^ " type, but " ^ type2string(aexp) ^ " found")
	      else ()
    end

    fun checkParaList (explist, tylist ,pos) =
     if (length(explist) <> length(tylist)) then
      err pos (Int.toString(length(tylist)) ^ " fields needed, but "
                   ^ Int.toString(length(explist)) ^ " given")
     else 
         case (explist,tylist,pos) of 
            ([],[],pos) => ()
          | (a1::l1,a2::l2,pos) => (checkTypeSame (a1,a2,pos);checkParaList(l1,l2,pos))
          | _ => err pos (Int.toString(length(tylist)) ^ " fields needed, but "^ Int.toString(length(explist)) ^ " given")

    fun checkInt( ty, pos) = 
    let val t = actual_ty (ty, pos) 
    in
        if t = T.INT 
        then ()
        else (err pos "interger required")
    end

    fun checkString( ty , pos) = 
    let val t = actual_ty (ty, pos) in
        if t = T.STRING 
        then ()
        else (err pos "string required")
    end

    fun checkEqual (lt,rt,pos) =
    let val alt = actual_ty (lt, pos) in
   		case alt of 
   		  T.INT => checkInt (rt, pos)
   		| T.STRING => checkString (rt,pos)
   		| T.ARRAY(t,u) => checkTypeSame (rt,T.ARRAY(t,u),pos)
   		| T.RECORD(sym,ty) => checkTypeSame(rt,T.RECORD(sym,ty), pos)
   		| _ => (err pos ("can only check equality on "
                      ^ "int, string, array or record types,"))
    end

    fun checkCompare (lt,rt,pos) = 
    let val alt = actual_ty (lt ,pos) in 
    	case alt of
    	  T.INT => checkInt (rt, pos)
    	| T.STRING => checkString(rt, pos)
    	| _ => (err pos ("can only compare int or string "))
    end

    fun transExp(venv,tenv,level,break) = 
        let fun trexp (A.VarExp(var)) = trvar var
        
        	  | trexp (A.NilExp) = {exp=(Tr.nilexp),ty=T.NIL}
			  
                  | trexp (A.IntExp(n)) = {exp=(Tr.intexp n),ty=T.INT}
              
          	  | trexp (A.StringExp(s,_)) = {exp=(Tr.strexp s),ty=T.STRING}
          	  
                  | trexp (A.OpExp{left, oper ,right, pos}) = 
                  let  val {exp,ty=lt} = trexp left
          			   val {exp,ty=rt} = trexp right
          		  in
 				    (case oper of 
 				      A.PlusOp => (checkInt(lt,pos); checkInt(rt,pos); {exp=(Tr.binop(le,oper,re)),ty=T.INT})
				    | A.MinusOp => (checkInt(lt,pos); checkInt(rt,pos); {exp=(Tr.binop(le,oper,re)),ty=T.INT})
					| A.TimesOp => (checkInt(lt,pos); checkInt(rt,pos); {exp=(Tr.binop(le,oper,re)),ty=T.INT})
					| A.DivideOp => (checkInt(lt,pos); checkInt(rt,pos); {exp=(Tr.binop(le,oper,re)),ty=T.INT})
					| A.LtOp => (checkCompare(lt,rt,pos); {exp=(Tr.relop(le,oper,re)),ty= actual_ty (lt,pos)})
					| A.GtOp => (checkCompare(lt,rt,pos); {exp=(Tr.relop(le,oper,re)),ty= actual_ty (lt,pos)})
					| A.LeOp => (checkCompare(lt,rt,pos); {exp=(Tr.relop(le,oper,re)),ty= actual_ty (lt,pos)})
					| A.GeOp => (checkCompare(lt,rt,pos); {exp=(Tr.relop(le,oper,re)),ty= actual_ty (lt,pos)})
					| A.EqOp => (checkEqual(lt,rt,pos); {exp=(Tr.relop(le,oper,re)),ty= actual_ty (lt,pos)})
              		| A.NeqOp => (checkEqual(lt,rt,pos); {exp=(Tr.relop(le,oper,re)),ty= actual_ty (lt,pos)}))
                        end
 				     
 		      | trexp (A.LetExp{decs,body,pos}) = 
 		            let val {venv = venv', tenv = tenv' } = 
 		                     transDecs(venv,tenv,decs)
 		            in transExp(venv',tenv',level,break) body
 		            end
 		           (* need change on let exp *) 
 		      | trexp (A.RecordExp {fields,typ, pos}) = 
 		        (case S.look(tenv,typ) of 
 		          NONE => 
 		          (err pos ("record type " ^ S.name typ ^ " not found");{exp = (), ty=T.UNIT})
 		        | SOME(t) => 
 		          (case actual_ty(t,pos) of 
 		            T.RECORD(tlist,u) => 
          			  let
          			    val ttlist = map (fn (sym,ty) => ty) tlist
          			    val fds = map (fn (a,b,pos) => (trexp b,pos)) fields
          			    val fts = map (fn ({exp,ty},pos) => ty) fds
          			    val fexp = map (fn ({exp,ty},_) => exp) fds
           			 in
              			checkParaList(ttlist,fts,pos);
             			 {exp=(Tr.record(fexp),ty=T.RECORD(tlist,u)}
           			 end
           		  | _ =>  (err pos ("expected record type, but " ^ type2string(actual_ty(t,pos)) ^ " found");
                                  {exp = (), ty=T.UNIT})
                           )
                         )
			
	         | trexp(A.SeqExp(exps)) =
          		let val ty = 
                            (case exps of [] => T.UNIT
          		                 | _ =>
                                             (case List.last exps of 
          		                         (exp,pos) => #ty (trexp exp)
          		                         ))
          		    val seqex = map (fn (ex,pos) => #exp (trexp ex)) exps
       			 in {exp=(Tr.sequence(seqex)),ty=ty} end
       			 
       		 | trexp (A.AssignExp{var,exp,pos}) =
       		    let val {exp = exp1,ty = ty1} = trvar var
                    val {exp = exp2,ty = ty2} = trexp exp 
                in
          			(checkTypeSame(ty1,ty2,pos);
          			 {exp=(Tr.assign(exp1,exp2)),ty=T.UNIT})
                end

			 | trexp (A.IfExp{test, then', else', pos}) =
     			  (checkInt(#ty (trexp test),pos);
      			   if isSome(else') then (checkTypeSame(#ty (trexp then'), #ty (trexp (valOf else')),pos);{exp = (Tr.ifexp(#ty (trexp test),#ty (trexp then'),#ty (trexp (valOf else'))), ty = #ty (trexp then')})
      			   else (checkTypeSame(#ty (trexp then'),T.UNIT,pos); {exp = (Tr.ifexp(#ty (trexp test),#ty (trexp then'),NONE), ty = #ty (trexp then')})


			 | trexp (A.WhileExp{test,body,pos}) =
      	   	    let
      	   	    	done_label = Temp.newlabel()
                    val {exp=test_exp,ty=test_ty} = trexp test
                    val {exp=body_exp,ty=body_ty} = transExp(venv,tenv,level,done_label) body
     		    in
      			    checkInt(test_ty,pos);
          			checkTypeSame(body_ty,T.UNIT,pos);
        		    {exp=(Tr.loop(test_exp,test_body,done_label),ty=T.UNIT}
                end
                
             (* what is done label here? *)   
			 | trexp (A.BreakExp(_)) = {exp=(Tr.break(break)),ty=T.UNIT}
			 
			 | trexp (A.ArrayExp{typ,size,init,pos}) =
			     (case S.look(tenv,typ) of
			       NONE => (err pos ("type " ^ S.name(typ) ^ " not found"); {exp = (), ty = T.UNIT})
			     | SOME(t) =>
			         let val at = actual_ty(t,pos) in
			              case at of
			                T.ARRAY(tt,_) =>
			                let val {exp=size_exp,ty=size_ty} = trexp size
			                    val {exp=init_exp,ty=init_ty} = trexp init
			                in
			                  checkInt(size_ty,pos);
			                  checkTypeSame(tt,init_ty,pos);
			                  {exp=(Tr.array(size_exp,init_exp),ty=at}
			                end
			              |_ => (err pos ("expected Array type, but " ^ type2string(at) ^ " found" );{exp = (), ty = T.UNIT})
           			 end)
			 
			 | trexp (A.ForExp{var,escape,lo,hi,body,pos}) =
			 	 let 
			 	   val {exp=lo_exp,ty=lo_ty} = trexp lo
			 	   val {exp=hi_exp,ty=hi_ty} = trexp hi
			 	 in (checkInt (lo_ty,pos);
			 		 checkInt (hi_ty,pos);
			 		 let 
			 	   		val startValue = A.SimpleVar(var,pos)
			 	   		val endSymbol = S.symbol "endValue"
			 	 		val endValue = A.SimpleVar(endSymbol,pos)
			 		    val letdecs=[A.VarDec{name=var,escape=escape,typ=NONE,init=lo,pos=pos}]
			 	   		val iplusexp = A.AssignExp{var=startValue,exp=A.OpExp{left=A.VarExp(startValue),oper=A.PlusOp,right=A.IntExp(1),pos=pos},pos=pos}
			 	   		val looptest = A.OpExp{left=A.VarExp(startValue),oper=A.LeOp,right=A.VarExp(endValue),pos=pos}
			 	   		val loopbody = A.SeqExp[(body,pos),(iplusexp,pos)]
			 	   		val whileloop = A.WhileExp{test=looptest,body=loopbody,pos=pos}
			 	    in 
			 	        trexp (A.LetExp{decs=letdecs,body=whileloop,pos=pos})
			 	    end)
			 	 end

			 | trexp (A.CallExp{func,args,pos}) =
			     case S.look(venv,func) of
			       NONE => (err pos ("Function " ^ S.name(func) ^ " is undeclared.");
			            {exp = (), ty = T.UNIT})
			     | SOME(E.VarEntry{ty}) =>
			           (err pos ("function expected, but variable of type: "
			                     ^ type2string(ty) ^ " found"); {exp = (), ty = T.UNIT})
			     | SOME(E.FunEntry{level=funlevel,label=nlabel,formals,result}) =>
			           let
			             val argtypelist = map trexp args 
			           in
			             checkParaList(map #ty argtypelist,formals,pos);
			             {exp=(R.call(level,funlevel,nlabel,map #exp argtypelist,T.UNIT),
			              ty=actual_ty(result,pos)}
                       end
		    (* no idea how call works *)
 		    and trvar (A.SimpleVar(id, pos)) = 
 		        (case S.look(venv,id)
 			        of SOME(E.VarEntry{access,ty}) => {exp=(Tr.simpleVar(access,level), ty = actual_ty (ty,pos)}
 			        |  NONE                 => (err pos ("undefined variable "^ S.name id);{exp=(), ty = T.UNIT})
                                | _ => (err pos ("undefined type "^ S.name id);{exp=(), ty = T.UNIT})
 			    )
 			    
 		          | trvar (A.FieldVar(var,sym,pos)) =
			          let val {exp=exp1,ty=ty1} = trvar var in
			              case ty1 of
			               T.RECORD(tylist,_) =>
			                 (case List.find (fn x => (#1 x) = sym) tylist of
			                    NONE => (err pos ("id: " ^ S.name sym ^ " not found");
			                      {exp=(),ty=T.NIL})
			                  | SOME(ft) =>  {exp=(Tr.fieldVar(exp1,List.length tylist), ty=actual_ty(#2 ft,pos)})
			                  
			               | _ => (err pos ("expected record type, but "
			                             ^ type2string(ty1) ^ " found"); {exp=(),ty=T.NIL})
			               end

			   
			      | trvar (A.SubscriptVar(var,exp,pos)) =
			          let val {exp = var_exp,ty = var_ty} = trvar var in
			              case actual_ty(var_ty,pos) of
			                T.ARRAY(t,_) =>
			               let val {exp=exp_exp,ty=exp_ty} = trexp exp in
			                     case exp_ty of
			                       T.INT => {exp=(Tr.subscriptVar(var_exp,exp_exp),ty=t}
			                       | _ =>
			                         (err pos ("array subscript should be int, but "
			                                 ^ type2string(exp_ty) ^ " found"); {exp=(),ty=T.UNIT})
			                      end
			              | _ => (err pos ("array required, but "
			                                 ^ type2string(actual_ty(var_ty,pos)) ^ " found"); {exp=(),ty=T.UNIT})
                      end
 		in 
 		    trexp
        end
	
	
	
	
    and transDec (venv, tenv, A.VarDec{name,escape, typ = NONE,init, pos}) = 
        let val {exp, ty} = transExp (venv, tenv, level, break) init
        in 
            case ty of
                T.NIL => (err pos "varible without declared type cannot use nil";
                          {tenv = tenv, venv = S.enter(venv, name, E.VarEntry{ty = ty})})
              | _ => {tenv = tenv, venv = S.enter(venv, name, E.VarEntry{ty = ty})}
        end

    | transDec (venv, tenv, A.VarDec{name,escape,typ = SOME (type_id, _),init, pos}) =
        let val {exp, ty} = transExp (venv, tenv, level, break) init
        in (case Symbol.look(tenv, type_id) of
            NONE    => (err pos "unknown type"; 
                       {tenv=tenv, venv=S.enter(venv, name, E.VarEntry{ty=ty})})
          | SOME dataty => 
                let
                    val dataty' = actual_ty(dataty, pos)
                in
                    checkTypeSame(dataty, ty, pos);
                    {tenv = tenv, venv = S.enter(venv, name, E.VarEntry{ty=ty})}
                end)
        end

	| transDec (venv, tenv, A.TypeDec(tydecs)) = 
	 	let val tenv' = List.foldr (fn(ty, env) => 
	 	                S.enter (env, #name ty, T.NAME (#name ty, ref NONE))) tenv tydecs
	 	    val tenv'' = List.foldr(fn(ty, env) => 
	 	    S.enter(env, #name ty, transTy(env, #ty ty))) tenv' tydecs

	 	   fun checkcycle(seen,to,pos) =
            case to of
              NONE => (err pos "type not found"; false)
            | SOME(t) =>
              case t of
                T.NAME(s2,r) =>
                if (List.all (fn (x) => x <> s2) seen)
                then checkcycle(s2::seen,!r,pos) else false
              | _ => true

            fun checkeach(nil) = ()
              | checkeach({name,ty,pos}::ds) =
                case S.look(tenv'',name) of
                  SOME(T.NAME(_,r)) =>
                  if (not (checkcycle([name], !r, pos))) then
                (err pos ("name type: " ^ S.name(name)
                          ^ " involved in cyclic definition."))
                  else checkeach(ds) 
                | _ => ()

	 	in 
	 	    checkeach(tydecs);
            checkdup(map #name tydecs, map #pos tydecs);
	 	    {venv = venv, tenv = tenv''}
        end
	 
	| transDec(venv, tenv, A.FunctionDec(fundecs)) = 
	 	let val venv' = List.foldr(fn(dec, env) => Symbol.enter(env, #name dec, transHeader(tenv, dec))) venv fundecs
	 	    fun runDec dec = 
	 	        case Symbol.look(venv', #name dec) of
	 	            NONE => ErrorMsg.impossible "No header found"
	 	          | SOME(Env.FunEntry entry) => transFun(venv', tenv, entry, dec)
	 	          | _ => ErrorMsg.impossible "Not function header"

	 	in  checkdup(map #name fundecs, map #pos fundecs);
	 	    List.map runDec fundecs;
	 	    {venv = venv', tenv = tenv}
	 	end

        and transDecs(venv, tenv, []) = {venv=venv, tenv=tenv}
           | transDecs(venv, tenv, dec::decs) =
               let val {tenv=tenv', venv=venv'} = transDec(venv, tenv, dec)
               in transDecs(venv', tenv', decs)
               end
	and transHeader(tenv, {name, params, result, body, pos}) =
	    let val params' = List.map #ty (List.map (transParam tenv) params)
	    in
	        (case result of
	        SOME (sym, pos) =>
	            (case Symbol.look(tenv, sym) of
	            NONE => (err pos "unkown type";
	            E.FunEntry{formals=params', result=T.UNIT})
	          | SOME (resTy) => E.FunEntry {formals=params', result=resTy} 
	            )
	      | NONE => Env.FunEntry{formals = params', result = T.UNIT}
	        )
	    end

	and transFun(venv, tenv, entry, {name, params, result, body, pos})=
	    (case result of 
	        SOME (res, resultPos) =>
	            (case Symbol.look (tenv, res) of
	                NONE => (err resultPos "unkown result type")
	              | SOME resultTy =>
	                    let val params' = List.map (transParam tenv) params
	                        fun addparam ({name, ty}, env) = 
	                            Symbol.enter(env, name, E.VarEntry {ty=ty})
	                        val venv' = List.foldr addparam venv params'
	                        val expResult = transExp(venv', tenv, level, break) body
	                    in

	                    	checkdup(map #name params, map #pos params);
	                        checkTypeSame(#ty expResult,resultTy, pos)
	                    end
	            )
	      | NONE => (
	            let val params' = List.map (transParam tenv) params
	                fun addparam ({name, ty}, env) = 
	                Symbol.enter(env, name, E.VarEntry {ty=ty})
	                val venv' = List.foldr addparam venv params'
	                val expResult = transExp(venv', tenv, level, break) body
	            in
	            	checkdup(map #name params, map #pos params);
	                checkTypeSame(#ty expResult,T.UNIT, pos)
	            end
	      )
	    )

	and transParam tenv {name,escape, typ = typSym, pos} = 
	    case Symbol.look (tenv, typSym) of
	        NONE => (err pos "undefined paramter type"; 
	                 {name = name, ty = T.NIL})
	      | SOME ty =>
	            {name=name, ty=ty}
	            
	and transTy (tenv,A.NameTy(sym,pos)) =
	    (case S.look(tenv,sym) of SOME(t) => t
                                    | NONE => T.UNIT)
	
	  | transTy (tenv,A.RecordTy(fields)) =
	    (checkdup(map #name fields, map #pos fields);
	     T.RECORD(
	     (map (fn {name,escape,typ,pos} =>
	              case S.look(tenv,typ) of
	                SOME(t) => (name,t)
	              | NONE => (err pos
	                             ("undefined type " ^ S.name typ);
	                         (name,T.UNIT))) fields), ref()))
	
	  | transTy (tenv,A.ArrayTy(sym,pos)) =
	    case S.look(tenv,sym) of
	      SOME(t) => T.ARRAY(t,ref())
	    | NONE => (err pos ("undefined type " ^ S.name sym);
               T.ARRAY(T.NIL,ref()))
	            
	            
	fun transProg(exp:Absyn.exp) =
    let
      val {exp,ty} =
          transExp (E.base_venv,E.base_tenv, level, break)(exp)
    in
      ()
    end

end

	 	
