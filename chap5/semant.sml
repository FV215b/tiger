structure Semant:
sig
    type venv
    type tenv
    type expty

    val transProg: Absyn.exp -> unit
end =
struct
  structure A = Absyn
  structure P = PrintAbsyn
  structure S = Symbol
  structure E = Env
  structure T = Types

(* transVar: venv * tenv * A.var -> expty *)
(* transExp: venv * tenv * A.exp -> expty *)
(* transDec: venv * tenv * A.dec -> {venv: venv, tenv: tenv} *)
(* transVar:        tenv * A.ty  -> T.ty  *)
