signature LIVENESS =
sig
  datatype inode = NODE of {temp: Temp.temp,
                                       adj: node list ref
                                      }

  datatype igraph = IGRAPH of {graph: inode list,
                               moves: (inode*inode) list}

  val interferenceGraph : Flow.flowgraph -> igraph

(*  val show : TextIO.outstream * igraph -> unit *)

end

structure TempKey : ORD_KEY =
struct
type ord_key = Temp.temp
fun compare (t1,t2) = String.compare(Temp.makestring t1,Temp.makestring t2)
end

structure Liveness :> LIVENESS =
struct

datatype inode = NODE of {temp: Temp.temp,
                                       adj: node list ref
                                      }

datatype igraph = IGRAPH of {graph: inode list,
                               moves: (inode*inode) list}


structure F = Flow
structure S = ListSetFn(TempKey)
structure T = Temp
structure TT = Temp.Table
structure IT = IntMapTable(type key=int fun getInt n = n)
structure FR = MipsFrame

type liveSet = S.set
type liveMap = liveSet IT.table

(* type tempEdge = {src:Temp.temp,dst:Temp.temp} *)

(*
fun show(output, IGRAPH{graph,moves}) =
  let
    fun p_status s =
      case s of
        I.INGRAPH(d) => "INGRAPH(" ^ Int.toString(d) ^ ")"
      | I.REMOVED => "REMOVED"
      | I.COLORED(r) => "COLORED(" ^ r ^ ")"

	  fun do1(node as I.NODE{temp,adj,status}) =
      TextIO.output(
        output,
        ("{temp=" ^ (T.makestring temp) ^ "," ^
         "status=" ^ p_status (!status) ^ "}\n"))
  in
    app do1 graph
  end
*)

fun lookTable (table,key) = valOf(IT.look(table,key))

fun interferenceGraph flowgraph =
  let
    fun iterLiveInOutMap(livein_map,liveout_map) =
    let
        val changed = ref false
        
        fun computeLiveOut(inmap,node) =
          case node of F.Node{succ,...} => foldl (fn (F.Node{id,...},s) => S.union(look(inmap,id),s)) S.empty (!succ)
                     | _ => ()
		
		fun computeLiveIn(node,(inmap,outmap) = 
		case node of F.Node{id,def,use,...} =>
			let val useSet = S.addList(S.empty,use)
			    val defSet = S.addList(S.empty,def)
			    val newOutSet = computeLiveOut(inmap,node)
			    val newInSet = S.union(useSet,S.difference(newOutSet,defSet))
			in (newOutSet,newInSet)
			end
		          | _ => (S.empty,S.empty)
		
		fun mapEnter(node,(inmap,outmap)) = 
		let
		    val oldOutSet = lookTable(outmap,(#id node)) (* Save old livein set *)
		    val oldInSet = lookTable(inmap,(#id node)) (* Save old liveout set *)
		    val (newOutSet,newInSet) = computeLiveIn(node,(inmap,outmap))
		in
		    if S.equal(newInSet,oldInSet) andalso S.equal(newOutSet,oldOutSet)
		    then () else changed := true;
		    (IT.enter(inmap,(#id node),newInSet),IT.enter(outmap,(#id node),newOutSet))
        end
		val (newInMap,newOutMap) = mapEnter(livein_map,liveout_map) flowgraph
    in
	    if !changed then iterLiveInOutMap (newInMap,newOutMap)
	    else newOutMap
    end
    	
    	
    fun Init_map () =  foldl (fn (F.Node{id,...},m) => IT.enter(m,id,S.empty)) IT.empty (List.rev flowgraph)

        

    (* move to in later? *)
    val liveout_map : liveMap = iter ((make_empty_map ()), (make_empty_map ()))


    (* set liveout for each node *)
    val _ =
      app
        (fn F.Node{id,liveout,...} =>
          case GT.look(liveout_map,id) of
              SOME s => liveout := S.listItems(s)
            | NONE => ErrorMsg.impossible("liveout map is not one-to-one")
        ) flowgraph;
     (* after that : origin in *)
     
in
(* the body of interferenceGraph *)

end
