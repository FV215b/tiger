structure Main =
struct
 fun main filename =
    let
      val syntaxTree = Parse.parse filename
    in
      PrintAbsyn.print syntaxTree;
      ()
    end
end
