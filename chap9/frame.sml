structure Frame : FRAME = struct
	val FP = Temp.newTemp()
	val wordSize = 32

	type frame = {
		name: Temp.label,
		formals: access list,
		locals: access list ref,
		nextLocalOffset: int ref
	}

	datatype access = InFrame of int
					| InReg of Temp.temp

	fun newFrame {name=name, formals=formals} = 
		let
			val pos = List.tabulate(length formals, fn n => (n*4)+8)
			val pair = ListPair.zip(pos, formals)
		in
			{name = name, formals = map toFormal v, nextLocalOffset = ref (0-4), locals = ref []}
		end

	fun toFormal (offset, escape) =
		if escape
		then InFrame offset
		else InReg (Temp.newTemp())

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

	fun formals {name: name, formals: formals, locals: locals, nextLocalOffset: nextLocalOffset} = formals

	fun allocLocal {name: name, formals: formals, locals: locals, nextLocalOffset: nextLocalOffset} escape = 
		let
			val l = toLocal nextLocalOffset escape
		in
			locals := l :: !locals;
			l
		end	
		

	fun procEntryExit {frame: frame, body: Tree.stm} = body

	fun exp (InFrame f) treeExp = Tree.MEM(Tree.BINOP(Tree.PLUS, treeExp, Tree.CONST f))
			| (InReg temp) treeExp = Tree.TEMP temp
end
