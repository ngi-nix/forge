module Main.Helpers.Markdown exposing (..)

import Html exposing (Html, text)
import Main.Helpers.Html exposing (..)
import Main.Update exposing (..)
import Markdown.Parser
import Markdown.Renderer exposing (Renderer, defaultHtmlRenderer)


render : String -> List (Html Update)
render input =
    input
        |> Markdown.Parser.parse
        |> Result.mapError
            (\err ->
                "Failed to parse markdown: "
                    ++ (err
                            |> List.map Markdown.Parser.deadEndToString
                            |> String.join "\n"
                       )
            )
        |> Result.andThen (Markdown.Renderer.render renderer)
        |> Result.withDefault [ text "Error rendering markdown." ]


renderer : Renderer (Html Update)
renderer =
    { defaultHtmlRenderer
        | codeBlock =
            \block ->
                block.body |> codeBlock
    }
