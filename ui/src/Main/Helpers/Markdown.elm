module Main.Helpers.Markdown exposing (..)

import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Main.Helpers.GfmAlert exposing (..)
import Main.Helpers.Html exposing (..)
import Main.Update exposing (..)
import Main.Update.Types exposing (..)
import Markdown.Block
import Markdown.Parser
import Markdown.Renderer exposing (Renderer, defaultHtmlRenderer)


type alias Markdown =
    String


render : Markdown -> Html Update
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
        |> Result.map (List.map (Markdown.Block.walk transformGfmAlerts))
        |> Result.andThen (Markdown.Renderer.render renderer)
        |> Result.mapError (\err -> [ text ("Render error: " ++ err) ])
        |> (\res ->
                case res of
                    Ok html ->
                        html

                    Err html ->
                        html
           )
        |> div [ class "markdown-content" ]


transformGfmAlerts : Markdown.Block.Block -> Markdown.Block.Block
transformGfmAlerts block =
    case block of
        Markdown.Block.BlockQuote blocks ->
            case blocks of
                (Markdown.Block.Paragraph ((Markdown.Block.Text txt) :: restInlines)) :: restBlocks ->
                    let
                        trimmed =
                            String.trimLeft txt

                        alertType =
                            findGfmAlert trimmed
                    in
                    case alertType of
                        Just aType ->
                            let
                                prefix =
                                    gfmAlertPrefix aType

                                prefixLen =
                                    String.length prefix

                                newText =
                                    String.dropLeft prefixLen trimmed |> String.trimLeft

                                newFirstPara =
                                    Markdown.Block.Paragraph (Markdown.Block.Text newText :: restInlines)
                            in
                            Markdown.Block.OrderedList Markdown.Block.Loose (gfmAlertToInt aType) [ newFirstPara :: restBlocks ]

                        Nothing ->
                            block

                _ ->
                    block

        _ ->
            block


renderer : Renderer (Html Update)
renderer =
    { defaultHtmlRenderer
        | codeBlock =
            \block ->
                block |> codeBlock
        , orderedList =
            \startingIndex items ->
                case intToGfmAlert startingIndex of
                    Just alertType ->
                        let
                            children =
                                List.concat items

                            alertTitle =
                                Html.p [ class "markdown-alert-title" ]
                                    [ gfmAlertIcon alertType
                                    , Html.text (gfmAlertTitle alertType)
                                    ]
                        in
                        div [ class ("markdown-alert " ++ gfmAlertClass alertType) ] (alertTitle :: children)

                    Nothing ->
                        Html.ol
                            (case startingIndex of
                                1 ->
                                    []

                                _ ->
                                    [ Html.Attributes.attribute "start" (String.fromInt startingIndex) ]
                            )
                            (items
                                |> List.map (\itemBlocks -> Html.li [] itemBlocks)
                            )
    }
