
signature ENV = 
sig
    type access
    type ty

    datatype enventry = VarEntry of {access: Translate.access, ty: ty}
                      | FunEntry of {level: Translate.level, label: Temp.label, formals: ty list, result: ty}

    val base_tenv: ty Symbol.table
    val base_venv: enventry Symbol.table
end


structure Env : ENV = 
struct
    structure S = Symbol
    structure T = Types

    type access = unit
    type ty = T.ty

    datatype enventry = VarEntry of {access: Translate.access, ty: ty}
                      | FunEntry of {level: Translate.level, label: Temp.label, formals: ty list, result: ty}

    val predefinedTypes = [("int", T.INT),("string", T.STRING),("unit", T.UNIT)]

    val base_tenv = List.foldr 
                    (fn((name, ty), tenv) => S.enter(tenv, S.symbol name, ty)) 
                    S.empty predefinedTypes

    val predefinedFuns = 
        [("nil", VarEntry {access=Translate.globalAccess, ty=T.NIL})
        ,("print", FunEntry {level=Translate.outermost, label=Temp.namedlabel "print", formals=[T.STRING], result=T.UNIT})
          ,("flush", FunEntry {level=Translate.outermost, label=Temp.namedlabel "flush", formals=[], result=T.UNIT})
          ,("getchar", FunEntry {level=Translate.outermost, label=Temp.namedlabel "getchar", formals=[], result=T.STRING})
          ,("ord", FunEntry {level=Translate.outermost, label=Temp.namedlabel "ord", formals=[T.STRING], result=T.INT})
          ,("chr", FunEntry {level=Translate.outermost, label=Temp.namedlabel "chr", formals=[T.INT], result=T.STRING})
          ,("size", FunEntry {level=Translate.outermost, label=Temp.namedlabel "size", formals=[T.STRING], result=T.INT})
          ,("substring", FunEntry {level=Translate.outermost, label=Temp.namedlabel "substring", formals=[T.STRING, T.INT, T.INT], result=T.STRING})
          ,("concat", FunEntry {level=Translate.outermost, label=Temp.namedlabel "concat", formals=[T.STRING, T.STRING], result=T.STRING})
          ,("not", FunEntry {level=Translate.outermost, label=Temp.namedlabel "not", formals=[T.INT], result=T.INT})
          ,("exit", FunEntry {level=Translate.outermost, label=Temp.namedlabel "exit", formals=[T.INT], result=T.UNIT})]

    val base_venv = List.foldr 
                    (fn ((name, enventry), venv) => S.enter (venv, S.symbol name, enventry))
                    S.empty predefinedFuns
end
