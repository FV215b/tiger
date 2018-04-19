structure Frame : FRAME = struct
	
	val FP = Temp.newtemp()
	val wordSize = 4
	datatype access = InFrame of int
					| InReg of Temp.temp
	

	type frame = {
		name: Temp.label,
		formals: access list,
		locals: int ref,
		instrs: Tree.stm list
	}
	
	type register = string

	
	datatype frag = PROC of {body: Tree.stm, frame: frame}
					| STRING of Temp.label * string

	val ZERO = Temp.newtemp()
	val RV = Temp.newtemp()
	val GP = Temp.newtemp()
	val SP = Temp.newtemp() 
	val FP = Temp.newtemp()
	val RA = Temp.newtemp()

	val v0 = Temp.newtemp()
	val v1 = Temp.newtemp()

	val a0 = Temp.newtemp()
	val a1 = Temp.newtemp()
	val a2 = Temp.newtemp()
	val a3 = Temp.newtemp()

	val t0 = Temp.newtemp()
	val t1 = Temp.newtemp()
	val t2 = Temp.newtemp()
	val t3 = Temp.newtemp()
	val t4 = Temp.newtemp()
	val t5 = Temp.newtemp()
	val t6 = Temp.newtemp()
	val t7 = Temp.newtemp()
	val t8 = Temp.newtemp()
	val t9 = Temp.newtemp()

	val s0 = Temp.newtemp()
	val s1 = Temp.newtemp()
	val s2 = Temp.newtemp()
	val s3 = Temp.newtemp()
	val s4 = Temp.newtemp()
	val s5 = Temp.newtemp()
	val s6 = Temp.newtemp()
	val s7 = Temp.newtemp()
	
	val k0 = Temp.newtemp()
	val k1 = Temp.newtemp()

	val specialregs = [ZERO, RV, GP, SP, FP, RA, k0, k1]
	val argregs = [a0, a1, a2, a3]
	val calleesaves = [s0, s1, s2, s3, s4, s5, s6, s7]
	val callersaves = [t0, t1, t2, t3, t4, t5, t6, t7, t8, t9, v0, v1]

	val reglist = [(ZERO, "$zero"), (RV, "$rv"), (v0, "$v0"), (v1, "$v1"),
					(a0, "$a0"), (a1, "$a1"), (a2, "$a2"), (a3, "$a3"),
					(t0, "$t0"), (t1, "$t1"), (t2, "$t2"), (t3, "$t3"),
					(t4, "$t4"), (t5, "$t5"), (t6, "$t6"), (t7, "$t7"),
					(s0, "$s0"), (s1, "$s1"), (s2, "$s2"), (s3, "$s3"),
					(s4, "$s4"), (s5, "$s5"), (s6, "$s6"), (s7, "$s7"),
					(t8, "$t8"), (t9, "$t9"), (k0, "$k0"), (k1, "$k1"),
					(GP, "$gp"), (SP, "$sp"), (FP, "$fp"), (RA, "$ra")]

	val tempMap = foldl (fn ((key, value), table) => Temp.Table.enter(table, key, value)) Temp.Table.empty reglist

	fun tempToString t = 
		case Temp.Table.look(tempMap, t) of
			SOME(v) => v
			| NONE => Temp.makestring t
	
	 val registers = map (fn (t) => case Temp.Table.look(tempMap, t) of 
							SOME(v) => v
							) (specialregs @ argregs @ calleesaves @ callersaves) 

    fun exp (InFrame f)= (fn (temp) => Tree.MEM(Tree.BINOP(Tree.PLUS, temp, Tree.CONST f)))
			| exp (InReg temp) = (fn (_) => Tree.TEMP temp)

	fun newFrame {name: Temp.label, formals: bool list} = 
		let
			fun iterate (nil, _) = nil
				| iterate (curr::a, offset) = 
					if curr
					then InFrame(offset)::iterate(a, offset+wordSize)
					else InReg(Temp.newtemp())::iterate(a, offset)
			val acc_list = iterate (formals, wordSize)
			fun view_shift (acc, r) = Tree.MOVE(exp acc (Tree.TEMP FP), Tree.TEMP r)
      		val shift_instrs = ListPair.map view_shift (acc_list, argregs)
		in
			{name = name, formals = acc_list, locals = ref 0, instrs = shift_instrs}
		end

	fun name ({name, formals, locals, instrs}: frame): Temp.label = name

	fun formals ({name, formals, locals, instrs}: frame): access list = formals

	fun allocLocal ({name, formals, locals, instrs}: frame) escape = 
		if escape
		then
			let
				val ret = InFrame((!locals+1)*(~wordSize)) 
			in
				locals := !locals + 1;
				ret
			end
		else InReg(Temp.newtemp())
	
	fun externalCall (str, args) = Tree.CALL(Tree.NAME(Temp.namedlabel str), args)	

	fun procEntryExit1 {frame: frame, body: Tree.stm} = body

	fun procEntryExit2 (frame, body) =
		body @
		[Assem.OPER{assem="",
				src=[ZERO,RA,SP]@calleesaves,
				dst=[],jump=SOME[]}]

	fun procEntryExit3 ({name, formals, locals, instrs}:frame, body) =
		{prolog = "PROCEDURE " ^ Symbol.name name ^ "\n",
			body = body,
			epilog = "END " ^ Symbol.name name ^ "\n"}


end
