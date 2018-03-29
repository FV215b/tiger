structure Frame : FRAME = struct
	
	val FP = Temp.newTemp()
	val wordSize = 32

	type frame = {
		name: Temp.label,
		formals: access list,
		locals: access list ref,
		nextLocalOffset: int ref
	}
	
	type register = string

	datatype access = InFrame of int
					| InReg of Temp.temp
	
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
		case Temp.table.look(tempMap, t) of
			SOME(v) => v
			| NONE => Temp.makestring t
	
	val registers = map (fn (t) => case Temp.table.look(tempMap, t) of 
							SOME(v) => v) (specialregs @ argregs @ calleesaves @ callersaves)

	fun newFrame {name=name, formals=formals} = 
		let
			val pos = List.tabulate(length formals, fn n => (n*4)+8)
			val pair = ListPair.zip(pos, formals)
		in
			{name = name, formals = map (fn (offset, escape) => 
											if escape
											then InFrame offset
											else InReg (Temp.newTemp())) pair, nextLocalOffset = ref (0-4), locals = ref []}
		end

	(* fun toFormal (offset, escape) =
		if escape
		then InFrame offset
		else InReg (Temp.newTemp()) *)

	fun toLocal nextLocalOffset escape = 
		if escape
		then
			let
				val offset := !nextLocalOffset
			in
				nextLocalOffset := offset - wordSize div 8
				InFrame offset
			end
		else InReg(temp.newTemp())

	fun formals {name:_, formals: formals, locals:_, nextLocalOffset:_} = formals

	fun allocLocal {name:_, formals:_, locals: locals, nextLocalOffset: nextLocalOffset} escape = 
		let
			val l = toLocal nextLocalOffset escape
		in
			locals := l :: !locals;
			l
		end	
		

	fun procEntryExit1 {frame: frame, body: Tree.stm} = body

	fun procEntryExit2 (frame, body) =
		body @
		[Assem.OPER{assem="",
				src=[ZERO,RA,SP]@calleesaves,
				dst=[],jump=SOME[]}]

	fun procEntryExit3 (FRAME{name, params, locals}, body) =
		{prolog = "PROCEDURE " ^ Symbol.name name ^ "\n",
			body = body,
			epilog = "END " ^ Symbol.name name ^ "\n"}

	fun exp (InFrame f) treeExp = Tree.MEM(Tree.BINOP(Tree.PLUS, treeExp, Tree.CONST f))
			| (InReg temp) treeExp = Tree.TEMP temp
end
