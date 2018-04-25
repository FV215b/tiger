structure Main = struct

structure Tr = Translate
structure F = Frame
structure A = Assem
structure M =  MipsGen
fun procHandler (proc,(ilist,alist))  =                          
let                              
    val (body,frame) = case proc of F.PROC{body,frame} => (body,frame)
    val stms = Canon.linearize body
    val stms' = Canon.traceSchedule(Canon.basicBlocks stms)
    val instrs = List.concat(map (M.codegen frame) stms')
    val instrs2 = Frame.procEntryExit2 (frame,instrs)
    val (instrs2',alloc) = RegAlloc.alloc instrs2
in 
    (instrs2'::ilist,alloc::alist)
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
