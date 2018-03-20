structure Semant: 
sig
    type expty
    type venv
    type tenv 

    val transExp: venv * tenv * Absyn.exp -> expty
    val transDec: venv * tenv * Absyn.dec -> {venv: venv, tenv: tenv}
    val transTy: tenv* Absyn.ty -> Types.ty
end = 

struct
    structure A = Absyn
    structure T = Types
    structure S = Symbol
    structure E = Env
    structure Tr = Translate

    type expty =  {exp:Tr.exp, ty: T.ty}
    type venv = Env.base_venv
    type tenv = Env.base_tenv

    val error = ErrorMsg.error
    
    fun type2string (ty:T.ty) = 
          case ty of 
		      T.NIL => "nil"
		    | T.UNIT => "unit"
			| T.INT => "int"
			| T.STRING => "string"
			| T.ARRAY(t,_) => "array of " ^ type2str(t)
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
            
    fun checkInt( ty, pos) = 
    let val t = actual_ty (ty, pos) 
    in
        if t = T.INT 
        then ()
        else (error pos "interger required")
    end

    fun checkString( ty , pos) = 
    let val t = actual_ty (ty, pos) in
        if t = T.STRING 
        then ()
        else (error pos "string required")
    end

    fun checkArray( ty, pos) = 
    let val t = actual_ty (ty, pos) in
    	if t = T.ARRAY
    	then ()
    	else (error pos " array required")
    end

    fun checkRecord( ty , pos) =
    let val t = actual_ty (ty, pos) in
     	if t = T.RECORD
     	then ()
     	else (error pos " record required")
    end
        
    fun checkEqual (lt,rt,pos) =
    let val alt = actual_ty (lt, pos) in
   		case alt of 
   		  T.INT => checkInt (rt, pos)
   		| T.STRING => checkString (rt,pos)
   		| T.ARRAY => checkArray (rt,pos)
   		| T.RECORD => checkRecord(rt, pos)
   		| _ => (err pos ("can only check equality on "
                      ^ "int, string, array or record types,"))
    end

    fun checkCompare (lt,rt,pos) = 
    let val alt = actual_ty (lt ,pos) in 
    	case alt of
    	  T.INT => checkInt (rt, pos)
    	| T.SRTING => checkString(rt, pos)
    	| _ => (err pos ("can only compare int or string "))
    end

    fun transExp(venv,tenv) = 
        let fun trexp (A.VarExp(var)) = trvar var
        
        	  | trexp (A.NilExp) = {exp=(),ty=T.NIL}
			  
                  | trexp (A.IntExp(n)) = {exp=(),ty=T.INT}
              
          	  | trexp (A.StringExp(s,_)) = {exp=(),ty=T.STRING}
          	  
                  | trexp (A.OpExp{lt, oper ,rt,pos}) = 
 				    (case oper of 
 				      A.PlusOp => (checkint(lt,pos); checkint(rt,pos); {exp=(),ty=T.INT})
				    | A.MinusOp => (checkint(lt,pos); checkint(rt,pos); {exp=(),ty=T.INT})
					| A.TimesOp => (checkint(lt,pos); checkint(rt,pos); {exp=(),ty=T.INT})
					| A.DivideOp => (checkint(lt,pos); checkint(rt,pos); {exp=(),ty=T.INT})
					| A.LtOp => (checkCompare(lt,rt,pos); {exp=(),ty= actual_ty (lt,pos)})
					| A.GtOp => (checkCompare(lt,rt,pos); {exp=(),ty= actual_ty (lt,pos)})
					| A.LeOp => (checkCompare(lt,rt,pos); {exp=(),ty= actual_ty (lt,pos)})
					| A.GeOp => (checkCompare(lt,rt,pos); {exp=(),ty= actual_ty (lt,pos)})
					| A.EqOp => (checkEqual(lt,rt,pos); {exp=(),ty= actual_ty (lt,pos)})
              		| A.NeqOp => (checkEqual(lt,rt,pos); {exp=(),ty= actual_ty (lt,pos)}))
 				     
 		      | trexp (A.LetExp{decs,body,pos}) = 
 		            let val {venv = venv', tenv = tenv' } = 
 		                     transDecs(venv,tenv,decs)
 		            in transExp(venv',tenv') body
 		            end
 		            
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
          			    val fts = map (fn ({e,t},pos) => (t,pos)) fds
           			 in
              			checkParaList(ttlist,fts,pos);
             			 {exp=(),ty=T.RECORD(tlist,u)}
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
          		                         (exp,pos) => #ty trexp exp
          		                         | _ => T.UNIT))
       			 in {exp=(),ty=ty} end
       			 
       		 | trexp (A.AssignExp{var,exp,pos}) =
       		    let val {exp = exp1,ty = ty1} = trvar var
                    val {exp = exp2,ty = ty2} = trexp exp 
                in
          			(checkTypeSame(ty1,ty2,pos);
          			 {exp=(),ty=T.UNIT})
                end

			 | trexp (A.IfExp{test, then', else', pos}) =
      			  (checkInt(#ty (trexp test));
      			   if isSome(else') then checkTypeSame(#ty (trexp then'), #ty (trexp (valOf else')),pos) 
      			   else checkTypeSame(#ty (trexp then'),T.UNIT,pos); {exp = (), ty = #ty (trexp then')})


			 | trexp (A.WhileExp{test,body,pos}) =
      	   	    let
                    val {exp=test_exp,ty=test_ty} = trexp test
                    val {exp=body_exp,ty=body_ty} = transExp(venv,tenv) body
     		    in
      			    checkInt(test_ty,pos);
          			checkTypeSame(body_ty,T.UNIT,pos);
        		    {exp=(),ty=T.UNIT}
                end
                
			 | trexp (A.BreakExp(_)) = {exp=(),ty=T.UNIT}
			 
			 | trexp (A.ArrayExp{typ,size,init,pos}) =
			     (case S.look(tenv,typ) of
			       NONE => err pos ("type " ^ S.name(typ) ^ " not found"; {exp = (), ty = T.UNIT})
			     | SOME(t) =>
			         let val at = actual_ty(t,pos) in
			              case at of
			                T.ARRAY(tt,_) =>
			                let val {exp=size_exp,ty=size_ty} = trexp size
			                    val {exp=init_exp,ty=init_ty} = trexp init
			                in
			                  checkInt(size_ty,pos);
			                  checkTypeSame(tt,init_ty,pos);
			                  {exp=(),ty=at}
			                end
			              |_ => (err pos "expected Array type, but " ^ type2string(at) ^ " found" ;{exp = (), ty = T.UNIT})
           			 end)
			 
			 | trexp (A.ForExp{var,escape,lo,hi,body,pos}) =
			 	 (case S.look(tenv,var) of 
			 	   NONE => err pos ("type " ^ S.name(var) ^ " not found";{exp = (), ty = T.UNIT})
			 	 | SOME(t) =>
			 	 	 let val at = actual_ty(t,pos) in 
			 	 	 	 case at of 
			 	 	 	 T.INT => 
			 	 	 	 let val {exp=lo_exp,ty=lo_ty} = trexp lo
			 	 	 	     val {exp=hi_exp,ty=hi_ty} = trexp hi
			 	 	 	     val {exp=body_exp,ty=body_ty} = trexp body
			 	 	 	 in
			 	 	 	     checkInt (lo_ty,pos);
			 	 	 	     checkInt (hi_ty,pos);
			 	 	 	     checkTypeSame (body_ty,T.UNIT,pos);
			 	 	 	     {exp = (), ty = T.UNIT}
			 	 	 	 end
			                        | _ => (err pos "expected Int type as for id, but " ^ type2string(at) ^ " found";{exp = (), ty = T.UNIT})
			 	 	 end)
			 	 	 
			 | trexp (A.CallExp{func,args,pos}) =
			     case S.look(venv,func) of
			       NONE => (err pos ("function " ^ S.name(func) ^ " is not defined");
			            {exp = (), ty = T.UNIT})
			     | SOME(E.VarEntry{access,ty}) =>
			           (err pos ("function expected, but variable of type: "
			                     ^ type2string(ty) ^ " found"); {exp = (), ty = T.UNIT})
			     | SOME(E.FunEntry{level=funlevel,label,formals,result}) =>
			           let
			             val argtypelist = map trexp args 
			           in
			             checkParaList(argtypelist,formals,pos);
			             {exp=(),
			              ty=actual_ty(result,pos)}
                       end
			 	 	 	     
 		    and trvar (A.SimpleVar(id, pos)) = 
 		        (case S.look(venv,id)
 			        of SOME(E.VarEntry{ty}) => {exp=(), ty = actual_ty ty}
 			        |  NONE                 => (error pos ("undefined variable "^ S.name id);{exp=(), ty = T.UNIT})
 			    )
 			    
 		          | trvar (A.FieldVar(var,sym,pos)) =
			          let val {exp=exp1,ty=ty1} = trvar var in
			              case ty1 of
			               T.RECORD(tylist,_) =>
			                 (case List.find (fn x => (#1 x) = sym) tylist of
			                    NONE => (err pos ("id: " ^ S.name sym ^ " not found");
			                      {exp=(),ty=T.NIL})
			                  | SOME(ft) =>  {exp=(), ty=actual_ty(#2 ft,pos)})
			                  
			               | _ => (err pos ("expected record type, but "
			                             ^ type2string(ty1) ^ " found"); {exp=(),ty=T.NIL})
			               end
			   
			      | trvar (A.SubscriptVar(var,exp,pos)) =
			          let val {exp = var_exp,ty = var_ty} = trvar var in
			              case actual_ty(var_ty,pos) of
			                T.ARRAY(t,_) =>
			               let val {exp=exp_exp,ty=exp_ty} = trexp exp in
			                     case exp_ty of
			                       T.INT => {exp=(),ty=t}
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
        let val {exp, ty} = transExp (venv, tenv, init)
        in {tenv = tenv, venv = S.enter(venv, name, E.VarEntry{ty = ty})}
        end

    | transDec (venv, tenv, A.VarDec{name,escape,typ = SOME (type_id, _),init, pos}) =
        let val {exp, ty} = transExp (venv, tenv, init)
        in (case Symbol.look(tenv, typy_id) of
            NONE    => (error pos "unknown type"; 
                       {venv=S.enter(venv, name, E.VarEntry{access=(), ty=ty})})
          | SOME dataty => 
                let
                    val dataty' = actual_ty(dataty, ty, pos)
                in
                    checkTypeSame(dataty, ty, pos)
                    {tenv = tenv, venv = S.enter(venv, name, E.VarEntry(access=(), ty=ty))}
                end)
        end

	| transDec (venv, tenv, A.TypeDec(tydecs)) = 
	 	let val tenv' = List.foldr (fn(ty, env) => 
	 	                S.enter (env, #name ty, T.NAME (#name ty, ref NONE))) tenv tydecs
	 	    val tenv'' = List.foldr(fn(ty, env) => 
	 	    Symbol.enter(env, #name ty, transTy(env, ty))) tenv' tydecs

	 	in {venv = venv, tenv = tenv''}
                end
	 
	| transDec(venv, tenv, A.FunctionDec(fundecs)) = 
	 	let val venv' = List.foldr(fn(dec, env) => Symbol.enter(env, #name dec, transHeader(tenv, dec))) venv fundecs
	 	    fun runDec dec = 
	 	        case Symbol.look(venv', #name dec) of
	 	            NONE => ErrorMsg.impossible "No header found"
	 	          | SOME(Env.FunEntry entry) => transFun(venv', tenv, entry, dec)
	 	          | _ => ErrorMsg.impossible "Not function header"

	 	in List.map runDec decs;
	 	    {venv = venv', tenv = tenv}
	 	end	

	and transHeader(tenv, {name, params, result, body, pos}) =
	    let val params' = List.map #ty (List.map (transParam tenv) params)
	    in
	        (case result of
	        SOME (sym, pos) =>
	            (case Symbol.look(tenv, sym) of
	            NONE => (error pos "unkown type";
	            E.FunEntry{formals=params', result=T.UNIT})
	          | SOME (resTy) => E.FunEntry {formals=params', result=resTy} 
	            )
	      | NONE => Env.FunEntry{formals = params', result = T.UNIT}
	        )
	    end

	and transFun(venv, tenv, entry, {name, params, result = SOME(result, resultPos), body, pos})=
	    (case result of 
	        SOME (result, resultPos) =>
	            (case Symbol.look (tenv, result) of
	                NONE => (error resultPos "unkown result type")
	              | SOME resultTy =>
	                    let val params' = List.map (transParam tenv) params
	                        fun addparam ({name, ty}, env) = 
	                            Symbol.enter(env, name, E.VarEntry {access=(), ty=ty})
	                        val venv' = List.foldr addparam venv params'
	                        val expResult = transExp(venv', tenv) body
	                    in
	                        checkTypeSame(resultTy, #ty expResult,pos)
	                    end
	            )
	      | NONE => ()
	    )

	and transParam(tenv, {name, typ = typSym, pos}) = 
	    case Symbol.look (tenv, typSym) of
	        NONE => (error pos "undefined paramter type"; 
	                 {name = name, ty = T.NIL})
	      | SOME ty =>
	            {name=name, ty=ty}
	            
	and transTy (tenv,A.NameTy(sym,pos)) =
	    (* detect mutually recursive types *)
	    (case S.look(tenv,sym) of SOME(t) => t)
	
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
          transExp (E.base_venv,E.base_tenv)(exp)
    in
      ()
    end

end

	 	
