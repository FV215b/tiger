structure Main =
struct
 fun main filename =
    let
      val syntaxTree = Parse.parse filename
    in
      PrintAbsyn.print (TextIO.stdOut, syntaxTree)
    end
end
