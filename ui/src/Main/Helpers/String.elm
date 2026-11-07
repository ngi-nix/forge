module Main.Helpers.String exposing (..)


stripSuffix : String -> String -> String
stripSuffix suffix input =
    if String.endsWith suffix input then
        String.dropRight (String.length suffix) input

    else
        input


{-| Quote a value for a POSIX shell if the shell can interpret its characters.
-}
shellQuote : String -> String
shellQuote input =
    if not (String.isEmpty input) && String.all isShellSafe input then
        input

    else
        "'" ++ String.replace "'" "'\\''" input ++ "'"


isShellSafe : Char -> Bool
isShellSafe char =
    Char.isAlphaNum char || String.contains (String.fromChar char) "-_./:=,@%+"
