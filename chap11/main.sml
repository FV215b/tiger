structure Main = struct

structure Tr = Translate
structure F = Frame
structure A = Assem

fun procHandler (proc,(ilist,alist))  =                          
let                              
    val (body,frame) = case proc of F.PROC{bdy,frm} => (bdy,frm)
    val stms = Canon.linearize body
    val stms' = Canon.traceSchedule(Canon.basicBlocks stms)
    val instrs = List.concat(map (MipsGen.codegen frame) stms')
    val instrs2 = Frame.procEntryExit2 (frame,instrs)
	val format1 = Assem.format(Frame.temp_name)
    val (instrs2',alloc) = RegAlloc.alloc(instrs2,frame)
in 
    (instrs2'::ilists,alloc::alist)
end


fun main filename =
let val absyn = Parse.parse filename
    val frags = Semant.transProg absyn
    val procs =
            List.filter
                (fn (x) => case x of
                               F.PROC(_) => true
                             | _ => false) frags
in foldr procHandler ([],[]) procs
end
                                                          
end                        
