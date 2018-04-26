
There are 2 sml files and 2 sig files we implemented in this phase. They are :
color.sml color.sig regalloc.sml regalloc.sig
We only implemented simplify part without coalescing and spilling. So the interface is differnt from the book. 
In Color.color, the function receives a Liveness.igraph which we get from Liveness, a initial allocation and a registers,
Then it should producte a allocation from Temp.temp to registers. 
Notice that we do not need spillCost since we don't spill (we raise exception when it spills). We also don't produce spill temp list
since we dont spill.
In Regalloc.alloc, it puts everything in Flow, Liveness and Color together. It taks a Assem.instr list and then produce
a allocation. 
Notice that we don't take Frame.frame since we don't rewrite the program.
