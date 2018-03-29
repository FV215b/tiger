structure MipsGen :> CODEGEN =
struct

structure Frame : FRAME = MipsFrame
structure A = Assem
structure T = Tree



fun codegen (frame) (stm: Tree.stm): Assem.instr list =
    let val ilist = ref (nil: A.instr list)
        fun emit x = ilist := x :: !ilist
        fun result(gen) = let val t = Temp.newtemp() in gen t; t end

        fun int n =
            if n >= 0 
            then Int.toString(n) 
            else ("-" ^ Int.toString(~n))


        fun munchStm(T.SEQ(a, b)) = (munchStm(a); munchStm(b))

          | munchStm(T.MOVE(T.MEM(T.BINOP(T.PLUS, e1, T.CONST i)), e2)) =
            emit(A.OPER{assem="sw `s0, " ^ int i ^ "(`s1)",
                        src=[munchExp e1, munchExp e2],
                        dst=[],jump=NONE})

          | munchStm(T.MOVE(T.MEM(T.BINOP(T.PLUS, T.CONST i, e1)), e2)) =
            emit(A.OPER{assem="sw `s0, " ^ int i ^ "(`s1)",
                        src=[munchExp e1, munchExp e2],
                        dst=[],jump=NONE})

          | munchStm(T.MOVE(T.MEM(T.BINOP(T.MINUS, e1, T.CONST i)), e2)) =
            emit(A.OPER{assem="sw `s0, " ^ int (-1*i) ^ "(`s1)",
                        src=[munchExp e1, munchExp e2],
                        dst=[],jump=NONE})

          | munchStm(T.MOVE(T.MEM(T.BINOP(T.MINUS, T.CONST i, e1)), e2)) =
            emit(A.OPER{assem="sw `s0, " ^ int (-1*i) ^ "(`s1)",
                        src=[munchExp e1, munchExp e2],
                        dst=[],jump=NONE})

          | munchStm(T.MOVE(T.MEM(e1), e2)) =
            emit(A.OPER{assem="sw `s0, 0(`s1)",
                        src=[munchExp e2, munchExp e1],
                        dst=[],jump=NONE})

          (* TODO 2, load to register (lw) *)
          | munchStm(T.MOVE((T.TEMP i, T.CONST n))) =
            emit(A.OPER{assem="li `d0, " ^ int n,
                        src=[],
                        dst=[],jump=NONE})

          | munchStm(T.MOVE(T.TEMP i, T.MEM(T.BINOP(T.PLUS, e1, T.CONST n)))) =
            emit(A.OPER{assem="lw `d0, " ^ int n ^ "(`s0)",
                        src=[munchExp e1],
                        dst=[i],jump=NONE})
 
          | munchStm(T.MOVE(T.TEMP i,T.MEM(T.BINOP(T.PLUS, T.CONST n, e1)))) =
            emit(A.OPER{assem="lw `d0, " ^ int n ^ "(`s0)",
                        src=[munchExp e1],
                        dst=[i],jump=NONE})

          | munchStm(T.MOVE(T.TEMP i, T.MEM(T.BINOP(T.MINUS, e1, T.CONST n)))) =
            emit(A.OPER{assem="lw `d0, " ^ int2str (-1*n) ^ "(`s0)",
                        src=[munchExp e1],
                        dst=[i],jump=NONE})

          | munchStm (T.MOVE(T.TEMP i, T.MEM(T.BINOP(T.MINUS, T.CONST n, e1)))) =
            emit(A.OPER{assem="lw `d0, " ^ int2str (-1*n) ^ "(`s0)",
                        src=[munchExp e1],
                        dst=[i],jump=NONE})

          (* TODO 3, move from register to register *)
          | munchStm (T.MOVE((T.TEMP i, e2))) =
            emit(A.MOVE{assem="move `d0, `s0",
                        src=munchExp e2,
                        dst=i})

          (* TODO branching *)
          | munchStm(T.JUMP(T.NAME lab, _)) =
            emit(A.OPER{assem="b `j0",
                        src=[],
                        dst=[],
                        jump=SOME([lab])})

          | munchStm(T.JUMP(e, labels)) =
            emit(A.OPER{assem="jr `s0",
                        src=[munchExp e],
                        dst=[],
                        jump=SOME(labels)})

          (* TODO when comparing with 0 *)
          | munchStm(T.CJUMP(T.GE, e1, T.CONST 0, l1, l2)) =
            emit(A.OPER{assem="bgez `s0, `j0\nb `j1",
                        src=[munchExp e1],
                        dst=[],
                        jump=SOME [l1,l2]})

          | munchStm(T.CJUMP(T.GT, e1, T.CONST 0, l1, l2)) =
            emit(A.OPER{assem="bgtz `s0, `j0\nb `j1",
                        src=[munchExp e1],
                        dst=[],                      
                        jump=SOME [l1,l2]})

          | munchStm(T.CJUMP(T.LE, e1, T.CONST 0, l1, l2)) =
            emit(A.OPER{assem="blez `s0, `j0\nb `j1",
                        src=[munchExp e1],
                        dst=[],
                        jump=SOME [l1,l2]})

          | munchStm(T.CJUMP(T.LT, e1, T.CONST 0, l1, l2)) =
            emit(A.OPER{assem="bltz `s0, `j0\nb `j1",
                        src=[munchExp e1],
                        dst=[],
                        jump=SOME [l1,l2]})

          | munchStm(T.CJUMP(T.EQ, e1, T.CONST 0, l1, l2)) =
            emit(A.OPER{assem="beqz `s0, `j0\nb `j1",
                        src=[munchExp e1],
                        dst=[],
                        jump=SOME [l1,l2]})

          | munchStm(T.CJUMP(T.NE, e1, T.CONST 0, l1, l2)) =
            emit(A.OPER{assem="bnez `s0, `j0\nb `j1",
                        src=[munchExp e1],
                        dst=[],
                        jump=SOME [l1,l2]})

          (* TODO more general cases *)

          | munchStm (T.CJUMP(T.GE, e1, e2, l1, l2)) =
            emit(A.OPER{assem="bge `s0, `s1, `j0\nb `j1",
                        src=[munchExp e1, munchExp e2],
                        dst=[],
                        jump=SOME [l1,l2]})

          | munchStm (T.CJUMP(T.UGE, e1, e2, l1, l2)) =
            emit(A.OPER{assem="bgeu `s0, `s1, `j0\nb `j1",
                        src=[munchExp e1, munchExp e2],
                        dst=[],
                        jump=SOME [l1,l2]})

          | munchStm (T.CJUMP(T.GT, e1, e2, l1, l2)) =
            emit(A.OPER{assem="bgt `s0, `s1, `j0\nb `j1",
                        src=[munchExp e1, munchExp e2],
                        dst=[],
                        jump=SOME [l1,l2]})

          | munchStm (T.CJUMP(T.UGT, e1, e2, l1, l2)) =
            emit(A.OPER{assem="bgtu `s0, `s1, `j0\nb `j1",
                        src=[munchExp e1, munchExp e2],
                        dst=[],
                        jump=SOME [l1,l2]})

          | munchStm (T.CJUMP(T.LT, e1, e2, l1, l2)) =
            emit(A.OPER{assem="blt `s0, `s1, `j0\nb `j1",
                        src=[munchExp e1, munchExp e2],
                        dst=[],
                        jump=SOME [l1,l2]})

          | munchStm (T.CJUMP(T.ULT, e1, e2, l1, l2)) =
            emit(A.OPER{assem="bltu `s0, `s1, `j0\nb `j1",
                        src=[munchExp e1, munchExp e2],
                        dst=[],
                        jump=SOME [l1,l2]})

          | munchStm (T.CJUMP(T.LE, e1, e2, l1, l2)) =
            emit(A.OPER{assem="ble `s0, `s1, `j0\nb `j1",
                        src=[munchExp e1, munchExp e2],
                        dst=[],
                        jump=SOME [l1,l2]})

          | munchStm (T.CJUMP(T.ULE, e1, e2, l1, l2)) =
            emit(A.OPER{assem="bleu `s0, `s1, `j0\nb `j1",
                        src=[munchExp e1, munchExp e2],
                        dst=[],
                        jump=SOME [l1,l2]})

          | munchStm (T.CJUMP(T.EQ, e1, e2, l1, l2)) =
            emit(A.OPER{assem="beq `s0, `s1, `j0\nb `j1",
                        src=[munchExp e1, munchExp e2],
                        dst=[],
                        jump=SOME [l1,l2]})

          | munchStm (T.CJUMP(T.NE, e1, e2, l1, l2)) =
            emit(A.OPER{assem="bne `s0, `s1, `j0\nb `j1",
                        src=[munchExp e1, munchExp e2],
                        dst=[],
                        jump=SOME [l1,l2]})

          | munchStm (T.EXP(T.CALL(e,args))) =
            (let val pairs = map (fn r => (Temp.newtemp (), r)) Frame.callersaves
            in
                 map (fn (a,r) => 
                 munchStm(T.MOVE(T.TEMP a, T.TEMP r))) pairs;
                 emit(A.OPER{
                      assem="jalr `s0",
                      src=munchExp(e) :: munchArgs(0,args),
                      dst=calldefs,
                      jump=NONE});
                 map (fn (a,r) => 
                 munchStm(T.MOVE(T.TEMP r, T.TEMP a))) (List.rev pairs);
                 ()
            end)

          | munchStm (T.EXP e) = (munchExp e; ())

        (* TODO memory ops *)

        and munchExp (T.MEM(T.CONST i)) =
            result(fn r => 
                   emit(A.OPER{assem="lw `d0, " ^ int i ^ "($zero)",
                               src=[],
                               dst=[r],
                               jump=NONE}))

          | munchExp (T.MEM(T.BINOP(T.PLUS, e1, T.CONST i))) =
            result(fn r => 
                   emit(A.OPER{assem="lw `d0, " ^ int2str i ^ "(`s0)",
                               src=[munchExp e1],
                               dst=[r],
                               jump=NONE}))

          | munchExp (T.MEM(T.BINOP(T.PLUS, T.CONST i, e2))) =
            result(fn r => 
                   emit(A.OPER{assem="lw `d0, " ^ int2str i ^ "(`s0)",
                               src=[munchExp e2],
                               dst=[r],
                               jump=NONE}))

          | munchExp (T.MEM(T.BINOP(T.MINUS, e1, T.CONST i))) =
            result(fn r => 
                   emit(A.OPER{assem="lw `d0, " ^ int2str (~i) ^ "(`s0)",
                               src=[munchExp e1],
                               dst=[r],
                               jump=NONE}))

          | munchExp (T.MEM(T.BINOP(T.MINUS, T.CONST i, e2))) =
            result(fn r => 
                   emit(A.OPER{assem="lw `d0, " ^ int2str (~i) ^ "(`s0)",
                               src=[munchExp e2],
                               dst=[r],jump=NONE}))

          (* TODO binary operations *)

          (* TODO 1, add/sub immediate *)

          | munchExp (T.BINOP(T.PLUS, e1, T.CONST i)) =
            result(fn r => 
                   emit(A.OPER{assem="addiu `d0, `s0, " ^ int2str i,
                               src=[munchExp e1],
                               dst=[r],jump=NONE}))

          | munchExp (T.BINOP (T.PLUS, T.CONST i, e1)) =
            result(fn r => 
                   emit(A.OPER{assem="addiu `d0, `s0, " ^ int2str i,
                               src=[munchExp e1],
                               dst=[r],jump=NONE}))

          | munchExp (T.BINOP(T.PLUS, e1, e2)) =
            result(fn r => 
                   emit(A.OPER{assem="add `d0, `s0, `s1",
                               src=[munchExp e1,munchExp e2],
                               dst=[r],jump=NONE}))

          | munchExp (T.BINOP(T.MINUS, e1, T.CONST i)) =
            result(fn r => 
                   emit(A.OPER{assem="addiu `d0, `s0, " ^ int2str (~i),
                               src=[munchExp e1],
                               dst=[r],jump=NONE}))

          (* div *)

          | munchExp (T.BINOP(T.DIV, e1, e2)) =
            result(fn r => 
                   emit(A.OPER{assem="div `d0, `s0, `s1",
                               src=[munchExp e1,munchExp e2],
                               dst=[r],jump=NONE}))

          (* mul *)

          | munchExp (T.BINOP(T.MUL, e1, e2)) =
            result(fn r => 
                   emit(A.OPER{assem="mul `d0, `s0, `s1",
                               src=[munchExp e1,munchExp e2],
                               dst=[r],jump=NONE}))

          | munchExp (T.BINOP(T.MINUS, e1, e2)) =
            result(fn r => 
                   emit(A.OPER{assem="sub `d0, `s0, `s1",
                               src=[munchExp e1, munchExp e2],
                               dst=[r],jump=NONE}))

          (* and *)

          | munchExp (T.BINOP (T.AND, e1, T.CONST n)) =
            result(fn r => 
                   emit(A.OPER{assem="andi `d0, `s0, " ^ int2str n,
                               src=[munchExp e1],
                               dst=[r],
                               jump=NONE}))

          | munchExp (T.BINOP (T.AND, T.CONST n, e1)) =
            result(fn r => 
                   emit(A.OPER{assem="andi `d0, `s0, " ^ int2str n,
                               src=[munchExp e1],
                               dst=[r],
                               jump=NONE}))

          | munchExp (T.BINOP (T.AND, e1, e2)) =
            result(fn r => 
                   emit(A.OPER{assem="and `d0, `s0, `s1",
                               src=[munchExp e1],
                               dst=[r],
                               jump=NONE}))

          (* or *)

          | munchExp (T.BINOP (T.OR, e1, T.CONST n)) =
            result(fn r => 
                   emit(A.OPER{assem="ori `d0, `s0, " ^ int2str n,
                               src=[munchExp e1],
                               dst=[r],
                               jump=NONE}))

          | munchExp (T.BINOP (T.OR, T.CONST n, e1)) =
            result(fn r => 
                   emit(A.OPER{assem="ori `d0, `s0, " ^ int2str n,
                               src=[munchExp e1],
                               dst=[r],
                               jump=NONE}))

          | munchExp (T.BINOP (T.OR, e1, e2)) =
            result(fn r => 
                   emit(A.OPER{assem="or `d0, `s0, `s1",
                               src=[munchExp e1],
                               dst=[r],
                               jump=NONE}))

          (* shift *)

          | munchExp (T.BINOP (T.LSHIFT, e, T.CONST n)) =
            result (fn r => 
                    emit (A.OPER {assem="sll `d0, `s0, " ^ int2str n,
                                  src=[munchExp e],
                                  dst=[r],
                                  jump=NONE}))

          | munchExp (T.BINOP (T.LSHIFT, e1, e2)) =
            result (fn r => 
                    emit (A.OPER {assem="sllv `d0, `s0, `s1",
                                  src=[munchExp e1, munchExp e2],
                                  dst=[r],
                                  jump=NONE}))

          | munchExp (T.BINOP (T.RSHIFT, e, T.CONST n)) =
            result (fn r => 
                    emit (A.OPER {assem="srl `d0, `s0, " ^ int2str n,
                                  src=[munchExp e],
                                  dst=[r],
                                  jump=NONE}))

          | munchExp (T.BINOP (T.RSHIFT, e1, e2)) =
            result (fn r => 
                    emit (A.OPER {assem="srlv `d0, `s0, `s1",
                                  src=[munchExp e1, munchExp e2],
                                  dst=[r],
                                  jump=NONE}))

          | munchExp (T.BINOP (T.ARSHIFT, e, T.CONST n)) =
            result (fn r => 
                    emit (A.OPER {assem="sra `d0, `s0, " ^ int2str n,
                                  src=[munchExp e],
                                  dst=[r],
                                  jump=NONE}))

          | munchExp (T.BINOP (T.ARSHIFT, e1, e2)) =
            result (fn r => 
                    emit (A.OPER {assem="srav `d0, `s0, `s1",
                                  src=[munchExp e1, munchExp e2],
                                  dst=[r],
                                  jump=NONE}))

          | munchExp (T.CONST i) =
            result(fn r => 
                   emit(A.OPER{assem="li `d0, " ^ int2str i,
                               src=[],
                               dst=[r],
                               jump=NONE}))

          | munchExp (T.MEM(e1)) =
            result(fn r => 
                   emit(A.OPER{assem="lw `d0, 0(`s0)",
                               src=[munchExp e1],dst=[r],jump=NONE}))

          | munchExp (T.TEMP t) = t

          | munchExp (T.NAME label) =
            result(fn r => 
                   emit(A.OPER{assem="la `d0, " ^ Symbol.name label,
                               src=[],
                               dst=[r],
                               jump=NONE}))

          | munchExp (T.CALL(e,args)) =
            (let
              val pairs = map (fn r => (Temp.newtemp (), r)) Frame.callersaves
            in
              map (fn (a,r) => 
              munchStm(T.MOVE(T.TEMP a, T.TEMP r))) pairs;
              result(fn r => emit(A.OPER{
                                  assem="jalr `s0",
                                  src=munchExp(e) :: munchArgs(0,args),
                                  dst=calldefs,
                                  jump=NONE}));
              map (fn (a,r) => 
              munchStm(T.MOVE(T.TEMP r, T.TEMP a))) (List.rev pairs);
              Frame.RV
            end)

        and munchArgs (_, []) = []
          | munchArgs (n, exp :: rest) =
              let val length = List.length Frame.argregs 
              in
                if n < length then
                  let val dst = List.nth(Frame.argregs,n)
                      val src = munchExp(exp) 
                  in munchStm(T.MOVE(T.TEMP dst,T.TEMP src));
                     dst :: munchArgs(n+1,rest)
                  end
                else ErrorMsg.impossible "Too many args"
            end

    in munchStm stm;
       rev(!ilist)
    end
end
