structure RegAlloc : REG_ALLOC =
struct
structure A = Assem
structure Frame = Frame
structure T = Temp
structure TT = T.Table
structure Tr = Tree

type allocation = Frame.register T.Table.table

fun alloc (instrs) : A.instr list * allocation = 
let  
     val graph = MakeGraph.instrs2graph instrs
     val igraph = Liveness.interferenceGraph graph
     val regAllocation = Color.color{interference=igraph,initial=Frame.tempMap,
                                             registers=Frame.registers}
     (* do we need to union the map of initial and regAllocation? *)

in (instrs,regAllocation)
end
end
