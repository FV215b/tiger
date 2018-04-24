structure Main = struct

structure Tr = Translate
structure F = Frame
structure A = Assem
structure S = Symbol

      


fun procHandler proc  =                          
let                              
    val (body,frame) = case proc of F.PROC{body,frame} => (body,frame)
in 
	Printtree.printtree (TextIO.stdOut,body);
	TextIO.print("\n\n\n")
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
