structure Main =
struct
 fun main filename =
    let
      val syntaxTree = Parse.parse filename
    in
      Semant.transProg syntaxTree;
      ()
    end
end