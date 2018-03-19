structure Semant: 
sig
    type expty
    type venv
    type tenv 

    transVar: venv * tenv * Absyn.var -> expty
    transExp: venv * tenv * Absyn.exp -> expty
    transDec: venv * tenv * Absyn.dec -> {venv: venv, tenv: tenv)
    transTy: tenv* Absyn.ty -> Types.ty
end = 

struct
    structure A = Absyn
    structure T = Types
    structure S = Symbol
    structure E = Env
    structure Tr = Translate

    type expty =  {exp:Translate.exp, ty: Types.ty}
    type venv = Env.base_venv
    type tenv = Env.base_tenv

    val error = ErrorMsg.error

    fun checkInt({exp, ty}, pos) = 
        if ty = T.INT 
        then ()
        else (error pos "interger required")

    fun checkString({ exp, ty }, pos) = 
        if ty = T.STRING 
        then ()
        else (error pos "string required")

  fun actual_ty (ty:T.ty,pos) =
      case ty of
        T.NAME(sym,tyref) =>
        (case (!tyref) of
           NONE => (err pos ("type undefined: " ^ S.name(sym)); T.NIL)
         | SOME(ty) => actual_ty (ty,pos))
      | T.ARRAY(t,u) => T.ARRAY(actual_ty(t,pos),u)
    | _ => ty

    fun transExp(venv,tenv) = 
        let fun trexp (A.OpExp{left, oper = A.PlusOp,right,pos}) = 
 				    (checkInt(trexp left, pos);
 				     checkInt(trexp right, pos);
 				     {exp = (), ty = Types.INT})
 		      | trexp (A.LetExp{decs,body,pos}) = 
 		            let val {venv = venv', tenv = tenv' } = 
 		                     transDecs(venv,tenv,decs)
 		            in transExp(venv',tenv') body
 		            end
 		      | trexp (A.RecordExp ...) ...
 		      (* more at here , need implement *)

 		    and fun trvar (A.SimpleVar(id, pos)) = 
 		        (case S.look(venv,id)
 			        of SOME(E.VarEntry{ty}) => {exp=(), ty = actual_ty ty}
 			        |  NONE                 => (error pos ("undefined variable "^ S.name id);
 			    )
 		        | trvar (A.FieldVar(v,id,pos)) = (* FunEntry at here? *)
 		in 
 		    trexp
        end

    and fun transDec (venv, tenv, A.VarDec{name,type = NONE,init,...}) = 
        let val {exp, ty} = transExp (venv, tenv, init)
        in {tenv = tenv, venv = S.enter(venv, name, E.VarEntry{ty = ty})}
        end

    | transDec (venv, tenv, A.VarDec{name,type = SOME (type_id, _),init,...}) =
        (case Symbol.look(tenv, typy_id) of
         NONE    => (error pos "unknown type"; {venv = venv, tenv = tenv})
         SOME ty => {tenv = tenv, venv = S.enter(venv, name, E.VarEntry(access=(), ty=ty))})

	| transDec (venv, tenv, A.TypeDec(tydecs) = 
	 	let val tenv' = List.foldr (fn(ty, env) => S.enter (env, #name ty, T.NAME (#name ty, ref NONE))) tenv tydecs
	 	in {venv = venv, 
	 	    tenv = List.foldr(fn(ty, env) => 
	 	    Symbol.enter(env, #name ty, transTy(env, ty))) tenv' tydecs
	 	    }
	 
	| transDec(venv, tenv, A.FunctionDec(fundecs)) = 
	 	let venv' = List.foldr(fn(dec, env) => Symbol.enter(env, #name dec, functionHeader(tenv, dec))) venv fundecs
	 	    fun runDec dec = 
	 	        case Symbol.look(venv', #name dec) of
	 	            NONE => ErrorMsg.impossible "No header found"
	 	          | SOME(Env.FunEntry entry) => transFun(venv', tenv, entry, dec)
	 	          | _ => ErrorMsg.impossible "Not function header"

	 	in List.map runDec decs;
	 	    {venv = venv', tenv = tenv}
	 	end	

    | transDec (venv, tenv, []) = {venv=venv, tenv=tenv}

	| transDec (venv, tenv, dec::decs) = 
	    let val {tenv=tenv', venv=venv'} = transDec(venv, tenv, dec)
	    in transDecs(venv', tenv', decs)
	    end

	and functionHeader(tenv, {name, params, result, body, pos}) =
	    let val params' = List.map #ty (List.map (transParam tenv) params)
	    in
	        (case result of
	        SOME (sym, pos) =>
	            (case Symbol.look(tenv, sym) of
	            NONE => (error pos "unkown type";
	            E.FunEntry{formals=params', result=T.UNIT})
	          | SOME => resTy => E.FunEntry {formals=params', result=resTy} 
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
end

	 	