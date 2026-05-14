module Main.Helpers.Html exposing (..)

import Html exposing (Attribute, Html, button, code, div, pre, text)
import Html.Attributes exposing (class)
import Html.Events
import Json.Decode
import Main.Icons exposing (iconCopy)
import Main.Update.Types exposing (..)
import Parser
import SyntaxHighlight as SH exposing (HCode, monokai, toBlockHtml, useTheme)


type alias CodeBlock =
    { body : String
    , language : Maybe String
    }


langCodeToParser : String -> (String -> Result (List Parser.DeadEnd) HCode)
langCodeToParser lang =
    case lang of
        "nix" ->
            SH.nix

        "python" ->
            SH.python

        "python3" ->
            SH.python

        "py" ->
            SH.python

        "json" ->
            SH.json

        "sql" ->
            SH.sql

        "sparql" ->
            SH.sql

        _ ->
            SH.noLang


plainCodeBlock : String -> Html Update
plainCodeBlock content =
    codeBlock
        { body = content
        , language = Nothing
        }


nixCodeBlock : String -> Html Update
nixCodeBlock content =
    codeBlock
        { body = content
        , language = Just "nix"
        }


codeBlock : CodeBlock -> Html Update
codeBlock body =
    let
        parser =
            body.language
                |> Maybe.withDefault ""
                |> langCodeToParser
    in
    div [ class "markdown-content position-relative" ]
        [ useTheme monokai
        , button
            [ class "btn btn-sm btn-secondary position-absolute top-0 end-0 m-2 button copy"
            , onClick (Update_CopyToClipboard body.body)
            ]
            [ iconCopy ]
        , parser body.body
            |> Result.map (toBlockHtml Nothing)
            |> Result.withDefault
                (pre
                    [ class "p-3 rounded border border-secondary" ]
                    [ code [] [ text body.body ] ]
                )
        ]


{-| `onClick` is like `Html.Events.onClick`
but prevents default action on internal links to avoid full page reloads.

The name conflicts on purpose to prevent accidental use of `Html.Events.onClick`.

Documentation: <https://github.com/mpizenberg/elm-url-navigation-port?tab=readme-ov-file#link-clicks>

-}
onClick : update -> Attribute update
onClick update =
    Html.Events.preventDefaultOn "click"
        (Json.Decode.succeed ( update, True ))


{-| Stop a click event from bubbling up to a parent element.
Use this on external links nested inside an `onClick` parent.
-}
onClickStopPropagation : Attribute Update
onClickStopPropagation =
    Html.Events.custom "click"
        (Json.Decode.succeed
            { message = Update_NoOp
            , stopPropagation = True
            , preventDefault = False
            }
        )
