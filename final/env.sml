
signature ENV = 
sig
    type access
    type ty

    datatype enventry = VarEntry of {access: Translate.access, ty: ty}
                      | FunEntry of {formals: ty list,level: Translate.level,label: Temp.label, result: ty}

    val base_tenv: ty Symbol.table
    val base_venv: enventry Symbol.table
end


structure Env : ENV = 
struct
    structure S = Symbol
    structure T = Types

    type access = unit
    type ty = T.ty
    type funinfo = string * ty list * ty

datatype enventry = VarEntry of {access: Translate.access, ty: ty}
                      | FunEntry of {formals: ty list,level: Translate.level,label: Temp.label, result: ty}

    val predefinedTypes = [("int", T.INT),("string", T.STRING),("unit", T.UNIT)]

    val base_tenv = List.foldr 
                    (fn((name, ty), tenv) => S.enter(tenv, S.symbol name, ty)) 
                    S.empty predefinedTypes

    val predefinedFuns: funinfo list = 
        [("print",[T.STRING],T.UNIT),
     ("printi",[T.INT],T.UNIT),
     ("flush",[],T.UNIT),
     ("getchar",[],T.STRING),
     ("ord",[T.STRING],T.INT),
     ("chr",[T.INT],T.STRING),
     ("size",[T.STRING],T.INT),
     ("substring",[T.STRING,T.INT,T.INT],T.INT),
     ("concat",[T.STRING,T.STRING],T.STRING),
     ("not",[T.INT],T.INT),
     ("exit",[T.INT],T.UNIT)]

    val base_venv =
    List.foldr
      (fn ((name,formals,result),env) =>
          let val label = Temp.namedlabel name in
            S.enter (env,S.symbol(name),
                     FunEntry{level=Translate.newLevel
                                        {parent=Translate.outermost,
                                         name=label,
                                         formals=map (fn _ => false) formals},
                              label=label,
                              formals=formals,
                              result=result})
          end)
      S.empty predefinedFuns
end
