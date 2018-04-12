signature LIVENESS =
sig
  datatype inode = NODE of {temp: Temp.temp,
                                       adj: inode list ref
                                      }

  datatype igraph = IGRAPH of {graph: inode list,
                               moves: (inode*inode) list}

  val interferenceGraph : Flow.flowgraph -> igraph

  val prt : TextIO.outstream * igraph -> unit 

end

structure TempKey : ORD_KEY =
struct
type ord_key = Temp.temp
fun compare (t1,t2) = String.compare(Temp.makestring t1,Temp.makestring t2)
end

structure Liveness :> LIVENESS =
struct

datatype inode = NODE of {temp: Temp.temp,
                                       adj: inode list ref
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
type tempEdge = {src:T.temp, dst:T.temp}

fun prt(IGRAPH{graph,moves}) =
  let
      fun adjtostring ilist = foldl (fn (nd,s) => s^ " " ^ (T.makestring (#temp nd))) "" ilist
	  fun prthelp(node as I.NODE{temp,adj,status}) =
      TextIO.print(
        ("{temp=" ^ (T.makestring temp) ^ ", and adj =" ^ adjtostring(adj) ^ "}\n"))
  in
    app prthelp graph
  end


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
		    val oldOutSet = lookTable(outmap,(#id node)) 
		    val oldInSet = lookTable(inmap,(#id node)) 
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

    val liveOutMap : liveMap = iterLiveInOutMap ((Init_map()), (Init_map()))
     
   fun moveEdge flowgraph = 
   let fun moveEdgeHelper (node,anslist) = if (#ismove node) then 
         let val definode = searchTempTable(List.hd (#def node))
           val useinode = searchTempTable(List.hd (#use node))
         in if isSome(List.find (fn (inode1,inode2) => (inode1 = definode) andalso (inode2 = useinode)) anslist) then anslist else (definode,useinode)::anslist
         end 
       else anslist 
   in
     foldl moveEdgeHelper [] flowgraph
   end

    fun inodeEdge (node as F.Node{def,liveout,...}) : tempEdge list = 
    let
        fun iterOut d = foldl (fn (out, l) => if d <> out then {src:d,dst:out}::l else l) nil liveout
    in
        foldl (fn (d) => (iterOut d) @ ll) nil def
    end

    val allEdges : tempEdge list = foldl (fn (n, l) => inodeEdge(n) @ l) nil flowgraph
    
in
(* the body of interferenceGraph *)
    app(
        fn {src,dst} =>
        let
            val src_inode as NODE{adj=src_adj,...} = searchTempTable(src)
            val dst_inode as NODE{adj=dst_adj,...} = searchTempTable(dst)
        in
            if List.exists (fn x => x=dst_inode) (!src_adj)
            andalso List.exists (fn x => y=src_inode) (!dst_adj)
            then
                ()
            else
                let in
                    src_adj := dst_inode::(!src_adj);
                    dst_adj := src_inode::(!dst_adj)
                end
        end
    ) allEdges;
    IGRAPH{graph=TT.listItems(tempmap), moves=moveEdge(flowgraph)}
end
