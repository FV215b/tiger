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
	        | (_,_) =>  err pos ("expected " ^ type2string(typ) ^ " type, but " ^ type2string(aexp) ^ " found");
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
    let t = actual_ty (ty, pos) in
        if t = T.INT 
        then ()
        else (error pos "interger required")

    fun checkString( ty , pos) = 
    let t = actual_ty (ty, pos) in
        if t = T.STRING 
        then ()
        else (error pos "string required")
    
    fun checkArray( ty, pos) = 
    let t = actual_ty (ty, pos) in
    	if t = T.ARRAY
    	then ()
    	else (error pos " array required")
    
    fun checkRecord( ty , pos) =
    let t = actual_ty (ty, pos) in
     	if t = T.RECORD
     	then ()
     	else (error pos " record required")
     	
        
    fun checkEqual (lt,rt,pos) =
    let alt = actual_ty (lt, pos) in
   		case alt of 
   		  T.INT => checkInt (rt, pos)
   		| T.STRING => checkString (rt,pos)
   		| T.ARRAY => checkArray (rt,pos)
   		| T.RECORD => checkRecord(rt, pos)
   		| _ => (err pos ("can only check equality on "
                      ^ "int, string, array or record types,"))
    
    fun checkCompare (lt,rt,pos) = 
    let alt = actual_ty (lt ,pos) in 
    	case alt 0f 
    	  T.INT => checkInt (rt, pos)
    	| T.SRTING => checkString(rt, pos)
    	| _ => (err pos ("can only compare int or string "))


    fun transExp(venv,tenv) = 
        let fun trexp (A.VarExp(var)) = trvar var
        
        	  | trexp (A.NilExp) = {exp=(),ty=T.NIL}
			  
			  | trexp (A.IntExp(n)) = {exp=(),ty=T.INT}
              
          	  | trexp (A.StringExp(s,_)) = {exp=(),ty=T.STRING}
          	  
			  | trexp (A.OpExp{lt, oper ,rt,pos}) = 
 				    case oper of 
 				      A.PlusOp => (checkint(lt,pos); checkint(rt,pos); {exp=(),ty=T.INT})
				    | A.MinusOp => (checkint(lt,pos); checkint(rt,pos); {exp=(),ty=T.INT})
					| A.TimesOp => (checkint(lt,pos); checkint(rt,pos); {exp=(),ty=T.INT})
					| A.DivideOp => (checkint(lt,pos); checkint(rt,pos); {exp=(),ty=T.INT})
					| A.LtOp => (checkCompare(lt,rt,pos); {exp=(),ty= actual_ty (lt,pos)})
					| A.GtOp => (checkCompare(lt,rt,pos); {exp=(),ty= actual_ty (lt,pos)})
					| A.LeOp => (checkCompare(lt,rt,pos); {exp=(),ty= actual_ty (lt,pos)})
					| A.GeOp => (checkCompare(lt,rt,pos); {exp=(),ty= actual_ty (lt,pos)})
					| A.EqOp => (checkEqual(lt,rt,pos); {exp=(),ty= actual_ty (lt,pos)})
              		| A.NeqOp => (checkEqual(lt,rt,pos); {exp=(),ty= actual_ty (lt,pos)})
 				     
 		      | trexp (A.LetExp{decs,body,pos}) = 
 		            let val {venv = venv', tenv = tenv' } = 
 		                     transDecs(venv,tenv,decs)
 		            in transExp(venv',tenv') body
 		            end
 		            
 		      | trexp (A.RecordExp {fields,typ, pos}) = 
 		        case S.look(tenv,typ) of 
 		          NONE => 
 		          (err pos ("record type " ^ S.name typ ^ " not found");
 		        | SOME(t) => 
 		          case actual_ty(t,pos) of 
 		            T.RECORD(tlist,u) => 
          			  let
          			    val ttlist = map (fn (sym,ty) => ty) tlist
          			    val fds = map (fn (a,b,pos) => (trexp b,pos)) fields
          			    val fts = map (fn ({e,t},pos) => (t,pos)) fds
           			 in
              			checkParaList(ttlist,fts,pos);
             			 {exp=(),ty=T.RECORD(tlist,u)}
           			 end
           		  | _ =>  err pos ("expected record type, but " ^ type2string(actual_ty(t,pos)) ^ " found"); 
			
			 | trexp(A.SeqExp(exps)) =
          		let val ty = case exps of [] => T.UNIT
          						        | _ => case List.last exps of 
          						                         (exp,pos) =>#ty (trexp exp)
          						                         | _ => T.UNIT
       			 in {exp=(),ty=ty} end
       			 
       		 | trexp (A.AssignExp{var,exp,pos}) =
       		    let val {exp = exp1,ty = ty1} = trvar var
                    val {exp = exp2,ty = ty2} = trexp exp 
                in
          			(checkTypeSame(ty1,ty2,pos);
          			 {exp=(),ty=T.UNIT})
                end

			 | trexp trexp (A.IfExp{test, then', else', pos}) =
      			  (checkInt(#ty (trexp test));
      			   if isSome(else') then checkTypeSame(#ty (trexp then'), #ty (trexp (valOf else')),pos)
      			   else checkTypeSame(#ty (trexp then'),T.UNIT,pos); {exp = (); ty = #ty (trexp then')}


			 | 
			 
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

	 	