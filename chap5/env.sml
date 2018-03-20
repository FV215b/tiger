
signature ENV = 
sig
    type access
    type ty

    datatype enventry = VarEntry of {ty: ty}
                      | FunEntry of {formals: ty list, result: ty}

    val base_tenv: ty Symbol.table
    val base_venv: enventry Symbol.table
end


structure Env : ENV = 
struct
    structure S = Symbol
    structure T = Types

    type access = unit
    type ty = T.ty

    datatype enventry = VarEntry of {ty: ty}
                      | FunEntry of {formals: ty list, result: ty}

    val predefinedTypes = [("int", T.INT),("string", T.STRING),("unit", T.UNIT)]

    val base_tenv = List.foldr 
                    (fn((name, ty), tenv) => S.enter(tenv, S.symbol name, ty)) 
                    S.empty predefinedTypes

    val predefinedFuns = 
        [("nil", VarEntry {ty=T.NIL})
        ,("print", FunEntry {formals=[T.STRING], result=T.UNIT})
          ,("flush", FunEntry {formals=[], result=T.UNIT})
          ,("getchar", FunEntry {formals=[], result=T.STRING})
          ,("ord", FunEntry {formals=[T.STRING], result=T.INT})
          ,("chr", FunEntry {formals=[T.INT], result=T.STRING})
          ,("size", FunEntry {formals=[T.STRING], result=T.INT})
          ,("substring", FunEntry {formals=[T.STRING, T.INT, T.INT], result=T.STRING})
          ,("concat", FunEntry {formals=[T.STRING, T.STRING], result=T.STRING})
          ,("not", FunEntry {formals=[T.INT], result=T.INT}) (* TODO: Tiger doesn't include a boolean type. Would be useful here. *)
          ,("exit", FunEntry {formals=[T.INT], result=T.UNIT})]

    val base_venv = List.foldr 
                    (fn ((name, enventry), venv) => S.enter (venv, S.symbol name, enventry))
                    S.empty predefinedFuns
end
