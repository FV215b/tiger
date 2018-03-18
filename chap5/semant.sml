structure Semant : 
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

    fun actual_ty ty = (* need implement *)

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
        let val {exp,ty} = transExp (venv,tenv,init)
            in {tenv = tenv,
            venv = S.enter(venv,name,E.VarEntry{ty=ty})}
        end (* recursive, only var x := exp, need more check at var x : type-id := exp *)
	 
	| transDec (venv, tenv, A.TypeDec[{name,ty}]) = 
	 	{venv=venv,tenv=S.enter(tenv,name,transTy(tenv,ty))}
	    (* only handles type-declaration list of length 1 *)
	 
	| transDec(venv, tenv, A.FunctionDec[{name,params,body,pos,result = SOME(rt,pos)}]) = 
	 	let val SOME(result_ty) = S.look(tenv,rt)
	        fun transparam{name,typ,pos} = 
	 			case S.look(tenv,typ)
	 			of SOME t => {name=name,ty=t}
	 		val params' = map transparam params
	 		val venv' = S.enter(venv,name, E.FunEntry{formals=map #ty params',result = result_ty})
	 		fun enterparam ({name,ty},venv) = S.enter(venv,name,E.VarEntry{access=(),ty=ty})
	 		val venv'' = fold entergaram params' venv'
	 	in transExp (venv'',tenv) body;
	 		{venv=venv',tenv=tenv}
	 	end
	        (* recursive *)		
end

	 	