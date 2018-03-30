signature FRAME =
sig
	type frame
	type access
	type register
	datatype frag = PROC of {body: Tree.stm, frame: frame}
					| STRING of Temp.label * string
	val newFrame : {name: Temp.label, formals: bool list} -> frame
	val name : frame -> Temp.label
	val formals : frame -> access list
	val allocLocal : frame -> bool -> access
	val ZERO : Temp.temp
	val RV : Temp.temp
	val GP : Temp.temp
	val SP : Temp.temp
	val FP : Temp.temp
	val RA : Temp.temp
	val specialregs : Temp.temp list
	val argregs : Temp.temp list
	val calleesaves : Temp.temp list
	val callersaves : Temp.temp list
	val wordSize : int
	val exp : access -> Tree.exp -> Tree.exp
	val externalCall : string * Tree.exp list -> Tree.exp
	val procEntryExit1 : {frame: frame, body: Tree.stm} -> Tree.stm
	val procEntryExit2 : frame * Assem.instr list -> Assem.instr list
	val procEntryExit3 : frame * Assem.instr list -> {prolog: string, body: Assem.instr list, epilog: string}
	val tempMap : register Temp.Table.table
	val tempToString : Temp.temp -> string
	val registers : register list
end
