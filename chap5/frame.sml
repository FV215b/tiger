 signature FRAME = 
 sig
    type frame
    type access

    val newFrame: {name: Temp.label, formals: bool list} -> frame
    val name: frame -> Temp.label
    val formals: frmae -> access list
    val allocLocal: frame -> bool -> access
    val string: Tree.label * string -> string

    val FP: Temp.temp
    val SP: Temp.temp
    
