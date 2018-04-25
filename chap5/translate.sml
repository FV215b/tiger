structure Translate : TRANSLATE =
struct

structure Frame : FRAME = MipsFrame

structure T = Tree

structure F = Frame

structure A = Absyn
(*define of level?*)

type access = level * Frame.access

datatype exp = Ex of T.exp
             | Nx of T.stm
             | Cx of Temp.label * Temp.label -> T.stm

fun unCx(Cx c) = c
  | unCx(Ex e) = (fn(t,f) => T.CJUMP(T.NE,e,T.CONST 0,t,f)
  | unCx(Ex (T.CONST 0)) = (fn(t,f) => JUMP(T.NAME f,[f])
  | unCx(Ex (T.CONST 1)) = (fn(t,f) => JUMP(T.NAME t,[t])
  | unCx(Nx _) = raise ErrorMsg.Error

fun unEx(Ex e) = e
  | unEx(Cx c) = 
  let val r = Temp.newtemp()
      val t = Temp.newlabel() and f = Temp.newlabel()
      in T.ESEQ(seq[T.MOVE(T.TEMP r, T.CONST 1),
                              c(t,f),T.LABEL f,
                              T.MOVE(T.TEMP r, T.CONST 0),
                              T.LABEL t],T.TEMP r)
      end
   | unEx (Nx s) = T.ESEQ(s,T.CONST 0)
   
fun unNx(Nx s) = s
  | unNx(Ex e) = T.EXP e
  | unNx(Cx c) = (* why do we need this? *)
  
fun translateIf(testexp,thenexp,elseexp: exp option): exp = 
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
 end (* return 0 if else is none? *)
 
 
 
 
