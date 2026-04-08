module Main.Helpers.String exposing (..)


stripSuffix : String -> String -> String
stripSuffix suffix input =
    if String.endsWith suffix input then
        String.dropRight (String.length suffix) input

    else
        input
