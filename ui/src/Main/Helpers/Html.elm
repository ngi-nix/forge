module Main.Helpers.Html exposing (..)

import Html exposing (Attribute, Html, button, details, div, node, summary, text)
import Html.Attributes exposing (attribute, class, style)
import Html.Events exposing (stopPropagationOn)
import Json.Decode
import Main.Config.App exposing (AppRuntime, showAppRuntime, showAppRuntimeDescription)
import Main.Icons exposing (iconCopy, iconDownload)
import Main.Update.Types exposing (..)


viewCountWidget : { total : Int, filtered : Int, noun : String, testId : String } -> Html Update
viewCountWidget { total, filtered, noun, testId } =
    let
        label =
            if filtered == total then
                String.fromInt total ++ " " ++ noun

            else
                String.fromInt filtered ++ " of " ++ String.fromInt total ++ " " ++ noun
    in
    Html.span
        [ class "btn btn-sm border d-inline-flex align-items-center flex-shrink-0"
        , style "color" "var(--bs-body-color)"
        , style "white-space" "nowrap"
        , attribute "data-testid" testId
        ]
        [ Html.text label ]


viewRuntimeBadge : AppRuntime -> Html Update
viewRuntimeBadge runtime =
    Html.span [ class "has-tooltip d-inline-block me-1", stopPropagationOn "click" (Json.Decode.succeed ( Update_NoOp, True )) ]
        [ Html.span [ class "badge rounded-pill bg-primary-subtle text-primary-emphasis border border-primary-subtle" ] [ Html.text (showAppRuntime runtime |> String.toLower) ]
        , div [ class "tooltip bs-tooltip-top", attribute "role" "tooltip" ]
            [ div [ class "tooltip-inner" ] [ Html.text (showAppRuntimeDescription runtime) ]
            ]
        ]


mdResolveLangCodeAlias : String -> String
mdResolveLangCodeAlias lang =
    case lang of
        "python3" ->
            "python"

        "py" ->
            "python"

        -- sparql is not sql but we don't need to bring in https://github.com/redmer/highlightjs-sparql
        -- for a single line in qlever app where sql highlighting works fine
        "sparql" ->
            "sql"

        any ->
            any


type alias FileTag =
    { language : String
    , filename : Maybe String
    }


defaultLanguage : String -> String
defaultLanguage lang =
    if String.isEmpty lang then
        "txt"

    else
        lang


extractExtension : String -> String
extractExtension filename =
    filename
        |> String.split "."
        |> List.reverse
        |> List.head
        |> Maybe.withDefault ""
        |> defaultLanguage


toOptionalString : String -> Maybe String
toOptionalString str =
    if String.isEmpty str then
        Nothing

    else
        Just str


{-| Parse language info strings and extract class.

See: <https://developer.mozilla.org/en-US/docs/MDN/Writing_guidelines/Howto/Markdown_in_MDN#additional_classes_info_strings>

-}
parseLanguageClass : String -> Maybe FileTag
parseLanguageClass tag =
    case String.split " " tag of
        [ "file" ] ->
            Just { language = "txt", filename = Nothing }

        [ filenameParts, "file" ] ->
            if String.contains "." filenameParts then
                Just
                    { language = extractExtension filenameParts
                    , filename = Just filenameParts
                    }

            else
                Just
                    { language = defaultLanguage filenameParts
                    , filename = Nothing
                    }

        language :: "file" :: filenameParts ->
            Just
                { language = defaultLanguage language
                , filename = toOptionalString (String.join ":" filenameParts)
                }

        _ ->
            Nothing


type alias CodeBlock =
    { body : String
    , language : Maybe String
    }


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


bashCodeBlock : String -> Html Update
bashCodeBlock content =
    codeBlock
        { body = content
        , language = Just "bash"
        }


codeBlock : CodeBlock -> Html Update
codeBlock body =
    let
        rawLang =
            Maybe.withDefault "" body.language

        fileTag =
            parseLanguageClass rawLang

        highlightLang =
            fileTag
                |> Maybe.map .language
                |> Maybe.withDefault rawLang
                |> mdResolveLangCodeAlias

        codeNode =
            node "highlightjs-code"
                [ attribute "language" highlightLang
                , attribute "body" body.body
                ]
                []

        copyBtn =
            button
                [ class "button copy"
                , onClick (Update_CopyToClipboard body.body)
                ]
                [ iconCopy ]

        downloadBtn filename =
            button
                [ class "button download"
                , onClick (Update_DownloadFile { filename = filename, content = body.body })
                ]
                [ iconDownload ]

        -- Shared flex container to keep buttons aligned without overlapping
        actionContainer buttons =
            div
                [ class "position-absolute top-0 end-0 m-2 d-flex gap-2"
                , style "z-index" "10"
                ]
                buttons
    in
    case fileTag of
        Just { filename } ->
            let
                name =
                    Maybe.withDefault "file.txt" filename
            in
            details [ class "markdown-content" ]
                [ summary [ class "file-summary" ] [ text name ]
                , div [ class "position-relative" ]
                    [ actionContainer [ downloadBtn name, copyBtn ]
                    , codeNode
                    ]
                ]

        Nothing ->
            div [ class "markdown-content position-relative" ]
                [ actionContainer [ copyBtn ]
                , codeNode
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
