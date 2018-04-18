structure Color : COLOR =
struct

structure L = Liveness
structure Frame = MipsFrame

(*
structure NS = BinarySetFn(
  type ord_key = LI.node
  fun compare(LI.NODE{temp=t1,...},LI.NODE{temp=t2,...})
      = String.compare(Temp.makestring t1,Temp.makestring t2))

structure MS = BinarySetFn(
  type ord_key = LI.node*LI.node
  fun compare((LI.NODE{temp=t1,...},
                LI.NODE{temp=t2,...}),
               (LI.NODE{temp=t1',...},
                LI.NODE{temp=t2',...})) =
    case String.compare(Temp.makestring t1,Temp.makestring t1') of
      EQUAL => String.compare(Temp.makestring t2,Temp.makestring t2')
     | od => od)

structure RS = ListSetFn(
    type ord_key = Frame.register
    fun compare (r1,r2) = String.compare(r1,r2))

structure WL = NS
*)

structure TT = Temp.Table
structure T = Temp


type allocation = Frame.register TT.table

(* coloring function *)
fun color{interference = L.IGRAPH{graph,moves},
          initial=initAlloc, registers} = 
let fun Simplify
	fun AssignColor
	val colorStack = Simplify(graph,initAlloc)
	val regAllocation = AssignColors {stack= colorStack,initial = initAlloc, register = registers}
in
    regAllocation
end

