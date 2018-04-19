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
          initial=initAlloc, registers} = ()
    let
        val lgraph = graph
        val stack : ref L.inode list
        val degreemap : ref TT.empty
        fun DecreaseDegree (node as L.NODE{temp,adj}) = 
        let 
            fun ddHelper (onenode as L.NODE{temp=oneTemp,adj=oneAdj}) = 
            case TT.look(!degreemap, oneTemp) of 
                SOME num => degreemap := TT.enter(!degreemap, oneTemp, num-1)
                | NONE => degreemap := TT.enter(!degreemap, oneTemp, (List.length !oneAdj)-1)
        in
            app ddHelper !adj
        end
        fun LookupDegree (node as L.NODE{temp,adj}) : bool = 
            case TT.look(!degreemap, temp) of
                SOME num => num < (List.length registers)
                | NONE => (degreemap := TT.enter(!degreemap, temp, (List.length !adj)); (List.length !adj) < (List.length registers))
        fun Simplify (livenessgraph, alloc) : () = 
            case List.find LookupDegree livenessgraph of
                SOME (findnode as L.NODE{temp,adj}) => (case TT.look(alloc, temp) of
                    SOME _ => (livenessgraph = List.filter (fn x => x <> findnode) livenessgraph; Simplify(livenessgraph, alloc))
                    | NONE => (DecreaseDegree(findnode); stack := findnode::(!stack); livenessgraph = List.filter (fn x => x <> findnode) livenessgraph; Simplify(livenessgraph, alloc))
                )
                | NONE => if List.length livenessgraph > 0 then ErrorMsg.impossible("Can't allocate registers" else ())

