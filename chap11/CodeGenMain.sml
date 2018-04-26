structure Main = struct

structure Tr = Translate
structure F = Frame
structure A = Assem
structure S = Symbol

      


fun procHandler proc  =                          
let                              
    val (body,frame) = case proc of F.PROC{body,frame} => (body,frame)
    val stms = Canon.linearize body
    val stms' = Canon.traceSchedule(Canon.basicBlocks stms)
    val instrs = List.concat(map (MipsGen.codegen frame) stms')
	val format1 = Assem.format(Frame.tempToString)
    fun instrPrint instr = TextIO.print((format1 instr) ^ "\n")
in 
	app instrPrint instrs''
end


fun main filename =
let val absyn = Parse.parse filename
    val frags = Semant.transProg absyn
    val procs  =
            List.filter
                (fn (x) => case x of
                               F.PROC(_) => true
                             | _ => false) frags
in 
    app procHandler procs
end
                                                          
end                        