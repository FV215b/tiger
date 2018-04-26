structure Main = struct

structure Tr = Translate
structure F = Frame
structure A = Assem
structure S = Symbol

fun tempalloc alloc temp = 
   case Temp.Table.look(alloc,temp) of 
        SOME(r) => r
      | NONE => Frame.tempToString temp
      
fun prtString (lab,str) = S.name lab ^ ": .asciiz \"" ^ str ^ "\"\n"

fun procHandler out proc  =                          
let                              
    val (body,frame) = case proc of F.PROC{body,frame} => (body,frame)
    val stms = Canon.linearize body
    val stms' = Canon.traceSchedule(Canon.basicBlocks stms)
    val instrs = List.concat(map (MipsGen.codegen frame) stms')
    val instrs2 = Frame.procEntryExit2 (frame,instrs)
    val (instrs2',alloc) = RegAlloc.alloc instrs2
    val {prolog,body,epilog} = Frame.procEntryExit3(frame,instrs2)
    fun instrPrint instr = TextIO.output(out,(Assem.format(tempalloc alloc) instr) ^ "\n")
in 
    TextIO.output(out,prolog);
	app instrPrint body;
    TextIO.output(out,epilog)
end

fun strHandler out (F.STRING(lab,str))= TextIO.output(out,prtString(lab,str))

fun main filename =
let val absyn = Parse.parse filename
    val frags = Semant.transProg absyn
    val (procs,strs) =
            List.partition
                (fn (x) => case x of
                               F.PROC(_) => true
                             | _ => false) frags
    val out = TextIO.openOut (filename ^ ".s") 
in 
    TextIO.output(out,"\t.globl main\n");
    TextIO.output(out,"\t.data\n");
	app (strHandler out) strs;
	TextIO.output(out,"\n\t.text\n");
    app (procHandler out) procs;
	TextIO.closeOut out;
    ()
end
                                                          
end                        
