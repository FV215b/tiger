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
    val (body,frame) = case proc of F.PROC{bdy,frm} => (bdy,frm)
    val stms = Canon.linearize body
    val stms' = Canon.traceSchedule(Canon.basicBlocks stms)
    val instrs = List.concat(map (MipsGen.codegen frame) stms')
    val instrs2 = Frame.procEntryExit2 (frame,instrs)
	val format1 = Assem.format(Frame.temp_name)
    val (instrs2',alloc) = RegAlloc.alloc(instrs2,frame)
    val {prolog,body,epilog} = Frame.procEntryExit3(frame,instrs2')
    fun instrPrint instr = TextIO.output(out,(Assem.format(tempalloc alloc) instr) ^ "\n")
in 
    TextIO.output(out,prolog);
	app instrPrint instrs'';
    TextIO.output(out,epilog)
end

fun strHandler out (str as F.STRING(lab,str))= TextIO.output(out,prtString(lab,str))

fun main filename =
let val absyn = Parse.parse filename
    val frags = Semant.transProg absyn
    val (procs,strs) =
            List.filter
                (fn (x) => case x of
                               F.PROC(_) => true
                             | _ => false) frags
    val out = TextIO.openOut (filename ^ ".s")
in 
    TextIO.output(out,"\t.globl main\n");
    TextIO.output(out,"\t.data\n");
	app (strHandler out) strs;
	TextIO.output(out,"\n\t.text\n");
    app (procHandler out) progs
end
                                                          
end                        
