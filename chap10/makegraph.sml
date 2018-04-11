
signature MAKE_GRAPH =
sig
  val instrs2graph: Assem.instr list -> Flowgraph.flowgraph
  val prt: Flow.flowgraph -> unit
end

structure MakeGraph : MAKE_GRAPH =
struct

structure T = Temp
structure F = Flowgraph

fun prt(nodes) =
  let
    fun templisttostring tlist = foldl (fn (tp,s) => s^ " " ^ (T.makestring tp)) "" tlist
    fun nodelisttostring nlist = foldl (fn (nd,s) => s^ " " ^ (Int.toString (#id nd))) "" nlist
  in
    app
      (fn (nd) =>
        TextIO.print(
          ("n" ^ (Int.toString (#id nd)) ^ ": " ^
           "def: " ^ (templisttostring (#def nd))^ "\n" ^
           "use: " ^ (templisttostring (#use nd)) ^ "\n" ^
           "succ: " ^ (nodelisttostring !(#succ nd))  ^ "\n" ^
           "prev: " ^ (nodelisttostring !(#prev nd))  ^ "\n" ))
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

fun instrs2graph  = 
let 
val idcounter = makeCounter 0
(* init the counter *)
fun make_node (instrs,nodelist) = 
  let val newnode = case instrs of Assem.oper{assem,dst,src,jump} 
  									=> F.node{id=idcounter(),def=dst,use=sec,ismove=false,succ=ref nil,prev=ref nil,liveout=ref nil}
         		                 | Assem.LABEL{assem,lab}
         		                 	=> F.node{id=idcounter(),def=nil,use=nil,ismove=false,succ=ref nil,prev=ref nil,liveout=ref nil}
         		                 | Assem.MOVE{assem,dst,src}
							        => F.node{id=idcounter(),def=[dst],use=[src],ismove=true,succ=ref nil,prev=ref nil,liveout=ref nil}
  in
  	  nodelist @ [newnode]
  end
  val nodelist = foldl make_node [] instrs
  val nodeAndInstrList = ListPair.zip(nodelist,instrs)
 
  fun make_edge(from, to) =
    if List.exists (fn n => n = to) !(#succ from) then ()
  else (#succ from):= to :: !(#succ from); (#prev to) := from :: !(#prev to))
  
  fun connectOtherNodes [] = ()
    | connectNodes [(node1,instr1)] = ()
    | connectNodes ((node1,instr1)::(node2,instr2)::rest) = 
    (case instr1 of 
          Assem.OPER{jump = some j,...} => ()
          (* we don't connect jump oper with other *)
        | _ => make_edge(node1,node2); connectNodes((node2,instr2)::rest))
  
  fun connectJumpNodes (node,instr)
  let fun findLabel label =  List.find (fn(_,instr) => case instr of Assem.LABEL{lab,...} => label=lab
                                                             | _ => false) nodeAndInstrList
  in 
      case instr of Assem.OPER{jump=SOME(jumplist),...}=>
      (map (fn lbl = if isSome(findLabel lbl) then make_edge(node, (#2 (findLabel lbl)))) jummplist
                  | _ => ()
   end
in
  map connectJumpNodes nodeAndInstrList;
  connectOtherNodes nodeAndInstrList;
  nodelist
end


end
 
  
