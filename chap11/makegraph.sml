
signature MAKE_GRAPH =
sig
  val instrs2graph: Assem.instr list -> Flow.flowgraph
  val prt: Flow.flowgraph -> unit
end

structure MakeGraph : MAKE_GRAPH =
struct

structure T = Temp
structure F = Flow

fun prt(nodes) =
  let
    fun templisttostring tlist = foldl (fn (tp,s) => s^ " " ^ (T.makestring tp)) "" tlist
    fun nodelisttostring nlist = foldl (fn (nd as F.Node{id,def,use,succ,prev,...},s) => s^ " " ^ (Int.toString id)) "" nlist
  in
    app
      (fn (nd as F.Node{id,def,use,succ,prev,...}) =>
        TextIO.print(
          ("n" ^ (Int.toString id) ^ ": " ^
           "def: " ^ (templisttostring def)^ "\n" ^
           "use: " ^ (templisttostring use) ^ "\n" ^
           "succ: " ^ (nodelisttostring (!succ))  ^ "\n" ^
           "prev: " ^ (nodelisttostring (!prev))  ^ "\n" ))
      )
      nodes
  end

fun makeCounter initVal =
	let val r = ref initVal
		in
        fn () => let val ans = !r
                      val () = r := ans + 1
                  in
      				   ans
                  end
        end
(* we first make a counter for id generation *)

fun instrs2graph instrs = 
let 
val idcounter = makeCounter 0
(* init the counter *)
fun make_node (instrs,nodelist) = 
  let val newnode = case instrs of Assem.OPER{assem,dst,src,jump} 
  									=> F.Node{id=idcounter(),def=dst,use=src,ismove=false,succ=ref nil,prev=ref nil}
         		                 | Assem.LABEL{assem,lab}
         		                 	=> F.Node{id=idcounter(),def=nil,use=nil,ismove=false,succ=ref nil,prev=ref nil}
         		                 | Assem.MOVE{assem,dst,src}
							        => F.Node{id=idcounter(),def=[dst],use=[src],ismove=true,succ=ref nil, prev=ref nil}
  in
  	  nodelist @ [newnode]
  end
  val nodelist = foldl make_node [] instrs
  val nodeAndInstrList = ListPair.zip(nodelist,instrs)
 
  fun make_edge(from as F.Node{succ,...}, to as F.Node{prev,...}) =
    if List.exists (fn n => n = to) (!succ) 
    then ()
    else ((succ):= to :: (!succ); (prev) := from :: !(prev))
  
  fun connectOtherNodes [] = ()
    | connectOtherNodes [(node1,instr1)] = ()
    | connectOtherNodes ((node1,instr1)::(node2,instr2)::rest) = 
    (case instr1 of 
          Assem.OPER{jump = SOME j,...} => ()
          (* we don't connect jump oper with other *)
        | _ => make_edge(node1,node2); connectOtherNodes((node2,instr2)::rest))
  
  fun connectJumpNodes (node,instr) =
  let fun findLabel label =  List.find (fn(_,instr) => case instr of Assem.LABEL{lab,...} => label=lab
                                                             | _ => false) nodeAndInstrList
  in 
      case instr of Assem.OPER{jump=SOME(jumplist),...}=>
      (app (fn lbl => 
      if isSome(findLabel lbl) 
      then 
      make_edge(node, (#1 (valOf(findLabel lbl))))
      else ()) jumplist )
      | _ => ()
   end
in
  map connectJumpNodes nodeAndInstrList;
  connectOtherNodes nodeAndInstrList;
  nodelist
end


end
 
  
