structure RegAlloc : REG_ALLOC =
struct
structure A = Assem
structure Frame = MipsFrame
structure T = Temp
structure TT = T.Table
structure Tr = Tree

type allocation = Frame.register T.Table.table

fun alloc (instrs,frame) : A.instr list * allocation = ()