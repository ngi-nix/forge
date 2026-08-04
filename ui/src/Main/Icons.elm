module Main.Icons exposing (..)

import Html exposing (Html, text)
import Html.Attributes exposing (attribute)
import Svg exposing (path, svg)
import Svg.Attributes exposing (class, d, fill, fillRule, height, rx, stroke, strokeLinecap, strokeLinejoin, strokeWidth, viewBox, width, x, y)



{-
   Resources:
   - https://html-to-elm.com
   - https://icons.getbootstrap.com/#icons
   - https://github.com/twbs/icons - Licensed MIT
-}


iconMoonStarsFill : Html msg
iconMoonStarsFill =
    svg
        [ width "16"
        , height "16"
        , fill "currentColor"
        , class "bi bi-moon-stars-fill"
        , attribute "data-testid" "icon-moon"
        , viewBox "0 0 16 16"
        ]
        [ path
            [ d "M6 .278a.77.77 0 0 1 .08.858 7.2 7.2 0 0 0-.878 3.46c0 4.021 3.278 7.277 7.318 7.277q.792-.001 1.533-.16a.79.79 0 0 1 .81.316.73.73 0 0 1-.031.893A8.35 8.35 0 0 1 8.344 16C3.734 16 0 12.286 0 7.71 0 4.266 2.114 1.312 5.124.06A.75.75 0 0 1 6 .278"
            ]
            []
        , path
            [ d "M10.794 3.148a.217.217 0 0 1 .412 0l.387 1.162c.173.518.579.924 1.097 1.097l1.162.387a.217.217 0 0 1 0 .412l-1.162.387a1.73 1.73 0 0 0-1.097 1.097l-.387 1.162a.217.217 0 0 1-.412 0l-.387-1.162A1.73 1.73 0 0 0 9.31 6.593l-1.162-.387a.217.217 0 0 1 0-.412l1.162-.387a1.73 1.73 0 0 0 1.097-1.097zM13.863.099a.145.145 0 0 1 .274 0l.258.774c.115.346.386.617.732.732l.774.258a.145.145 0 0 1 0 .274l-.774.258a1.16 1.16 0 0 0-.732.732l-.258.774a.145.145 0 0 1-.274 0l-.258-.774a1.16 1.16 0 0 0-.732-.732l-.774-.258a.145.145 0 0 1 0-.274l.774-.258c.346-.115.617-.386.732-.732z"
            ]
            []
        ]


iconSunFill : Html msg
iconSunFill =
    svg
        [ width "16"
        , height "16"
        , fill "currentColor"
        , class "bi bi-sun-fill"
        , attribute "data-testid" "icon-sun"
        , viewBox "0 0 16 16"
        ]
        [ path
            [ d "M8 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8M8 0a.5.5 0 0 1 .5.5v2a.5.5 0 0 1-1 0v-2A.5.5 0 0 1 8 0m0 13a.5.5 0 0 1 .5.5v2a.5.5 0 0 1-1 0v-2A.5.5 0 0 1 8 13m8-5a.5.5 0 0 1-.5.5h-2a.5.5 0 0 1 0-1h2a.5.5 0 0 1 .5.5M3 8a.5.5 0 0 1-.5.5h-2a.5.5 0 0 1 0-1h2A.5.5 0 0 1 3 8m10.657-5.657a.5.5 0 0 1 0 .707l-1.414 1.415a.5.5 0 1 1-.707-.708l1.414-1.414a.5.5 0 0 1 .707 0m-9.193 9.193a.5.5 0 0 1 0 .707L3.05 13.657a.5.5 0 0 1-.707-.707l1.414-1.414a.5.5 0 0 1 .707 0m9.193 2.121a.5.5 0 0 1-.707 0l-1.414-1.414a.5.5 0 0 1 .707-.707l1.414 1.414a.5.5 0 0 1 0 .707M4.464 4.465a.5.5 0 0 1-.707 0L2.343 3.05a.5.5 0 1 1 .707-.707l1.414 1.414a.5.5 0 0 1 0 .708"
            ]
            []
        ]


iconSearch : Html msg
iconSearch =
    svg
        [ width "16"
        , height "16"
        , fill "currentColor"
        , class "bi bi-search"
        , viewBox "0 0 16 16"
        ]
        [ path
            [ d "M11.742 10.344a6.5 6.5 0 1 0-1.397 1.398h-.001q.044.06.098.115l3.85 3.85a1 1 0 0 0 1.415-1.414l-3.85-3.85a1 1 0 0 0-.115-.1zM12 6.5a5.5 5.5 0 1 1-11 0 5.5 5.5 0 0 1 11 0"
            ]
            []
        ]


iconBookHalf : Html msg
iconBookHalf =
    svg
        [ width "16"
        , height "16"
        , fill "currentColor"
        , class "bi bi-book-half"
        , viewBox "0 0 16 16"
        ]
        [ path
            [ d "M8.5 2.687c.654-.689 1.782-.886 3.112-.752 1.234.124 2.503.523 3.388.893v9.923c-.918-.35-2.107-.692-3.287-.81-1.094-.111-2.278-.039-3.213.492zM8 1.783C7.015.936 5.587.81 4.287.94c-1.514.153-3.042.672-3.994 1.105A.5.5 0 0 0 0 2.5v11a.5.5 0 0 0 .707.455c.882-.4 2.303-.881 3.68-1.02 1.409-.142 2.59.087 3.223.877a.5.5 0 0 0 .78 0c.633-.79 1.814-1.019 3.222-.877 1.378.139 2.8.62 3.681 1.02A.5.5 0 0 0 16 13.5v-11a.5.5 0 0 0-.293-.455c-.952-.433-2.48-.952-3.994-1.105C10.413.809 8.985.936 8 1.783"
            ]
            []
        ]


iconList : List String -> Html msg
iconList classes =
    svg
        [ width "16"
        , height "16"
        , fill "currentColor"
        , class ("bi bi-list " ++ String.join " " classes)
        , viewBox "0 0 16 16"
        ]
        [ path
            [ fillRule "evenodd"
            , d "M2.5 12a.5.5 0 0 1 .5-.5h10a.5.5 0 0 1 0 1H3a.5.5 0 0 1-.5-.5m0-4a.5.5 0 0 1 .5-.5h10a.5.5 0 0 1 0 1H3a.5.5 0 0 1-.5-.5m0-4a.5.5 0 0 1 .5-.5h10a.5.5 0 0 1 0 1H3a.5.5 0 0 1-.5-.5"
            ]
            []
        ]



-- From nix.dev/install-nix copy icon
-- sphinx or pydata-sphinx-theme icon


iconCopy : Html msg
iconCopy =
    svg
        [ width "16"
        , height "16"
        , viewBox "0 0 24 24"
        , strokeWidth "1.5"
        , stroke "#f0f0f0"
        , fill "none"
        , strokeLinecap "round"
        , strokeLinejoin "round"
        ]
        [ Svg.title []
            [ text "Copy to clipboard" ]
        , path
            [ stroke "none"
            , d "M0 0h24v24H0z"
            , fill "none"
            ]
            []
        , Svg.rect
            [ x "8"
            , y "8"
            , width "12"
            , height "12"
            , rx "2"
            ]
            []
        , path
            [ d "M16 8v-2a2 2 0 0 0 -2 -2h-8a2 2 0 0 0 -2 2v8a2 2 0 0 0 2 2h2"
            ]
            []
        ]


iconInfoCircle : Html msg
iconInfoCircle =
    svg
        [ width "16"
        , height "16"
        , fill "currentColor"
        , class "bi bi-info-circle"
        , viewBox "0 0 16 16"
        ]
        [ path
            [ d "M8 15A7 7 0 1 1 8 1a7 7 0 0 1 0 14m0 1A8 8 0 1 0 8 0a8 8 0 0 0 0 16"
            ]
            []
        , path
            [ d "m8.93 6.588-2.29.287-.082.38.45.083c.294.07.352.176.288.469l-.738 3.468c-.194.897.105 1.319.808 1.319.545 0 1.178-.252 1.465-.598l.088-.416c-.2.176-.492.246-.686.246-.275 0-.375-.193-.304-.533zM9 4.5a1 1 0 1 1-2 0 1 1 0 0 1 2 0"
            ]
            []
        ]


iconLightbulb : Html msg
iconLightbulb =
    svg
        [ width "16"
        , height "16"
        , fill "currentColor"
        , class "bi bi-lightbulb"
        , viewBox "0 0 16 16"
        ]
        [ path
            [ d "M2 6a6 6 0 1 1 10.174 4.31c-.203.196-.359.4-.453.619l-.762 1.769A.5.5 0 0 1 10.5 13a.5.5 0 0 1 0 1 .5.5 0 0 1 0 1l-.224.447a1 1 0 0 1-.894.553H6.618a1 1 0 0 1-.894-.553L5.5 15a.5.5 0 0 1 0-1 .5.5 0 0 1 0-1 .5.5 0 0 1-.46-.302l-.761-1.77a2 2 0 0 0-.453-.618A5.98 5.98 0 0 1 2 6m6-5a5 5 0 0 0-3.479 8.592c.263.254.514.564.676.941L5.83 12h4.342l.632-1.467c.162-.377.413-.687.676-.941A5 5 0 0 0 8 1"
            ]
            []
        ]



-- Created by mixing chat-left.svg and exclamation.svg


iconChatLeftExclamation : Html msg
iconChatLeftExclamation =
    svg
        [ width "16"
        , height "16"
        , fill "currentColor"
        , class "bi bi-chat-left-exclamation"
        , viewBox "0 0 16 16"
        ]
        [ path
            [ d "M14 1a1 1 0 0 1 1 1v8a1 1 0 0 1-1 1H4.414A2 2 0 0 0 3 11.586l-2 2V2a1 1 0 0 1 1-1zM2 0a2 2 0 0 0-2 2v12.793a.5.5 0 0 0 .854.353l2.853-2.853A1 1 0 0 1 4.414 12H14a2 2 0 0 0 2-2V2a2 2 0 0 0-2-2z"
            ]
            []
        , path
            [ d "M7.002 11a1 1 0 1 1 2 0 1 1 0 0 1-2 0M7.1 4.995a.905.905 0 1 1 1.8 0l-.35 3.507a.553.553 0 0 1-1.1 0z"
            , attribute "transform" "translate(0, -2)"
            ]
            []
        ]


iconExclamationTriangle : Html msg
iconExclamationTriangle =
    svg
        [ width "16"
        , height "16"
        , fill "currentColor"
        , class "bi bi-exclamation-triangle"
        , viewBox "0 0 16 16"
        ]
        [ path
            [ d "M7.938 2.016A.13.13 0 0 1 8.002 2a.13.13 0 0 1 .063.016.15.15 0 0 1 .054.057l6.857 11.667c.036.06.035.124.002.183a.2.2 0 0 1-.054.06.1.1 0 0 1-.066.017H1.146a.1.1 0 0 1-.066-.017.2.2 0 0 1-.054-.06.18.18 0 0 1 .002-.183L7.884 2.073a.15.15 0 0 1 .054-.057m1.044-.45a1.13 1.13 0 0 0-1.96 0L.165 13.233c-.457.778.091 1.767.98 1.767h13.713c.889 0 1.438-.99.98-1.767z"
            ]
            []
        , path
            [ d "M7.002 12a1 1 0 1 1 2 0 1 1 0 0 1-2 0M7.1 5.995a.905.905 0 1 1 1.8 0l-.35 3.507a.552.552 0 0 1-1.1 0z"
            ]
            []
        ]


iconExclamationOctagon : Html msg
iconExclamationOctagon =
    svg
        [ width "16"
        , height "16"
        , fill "currentColor"
        , class "bi bi-exclamation-octagon"
        , viewBox "0 0 16 16"
        ]
        [ path
            [ d "M4.54.146A.5.5 0 0 1 4.893 0h6.214a.5.5 0 0 1 .353.146l4.394 4.394a.5.5 0 0 1 .146.353v6.214a.5.5 0 0 1-.146.353l-4.394 4.394a.5.5 0 0 1-.353.146H4.893a.5.5 0 0 1-.353-.146L.146 11.46A.5.5 0 0 1 0 11.107V4.893a.5.5 0 0 1 .146-.353zM5.1 1 1 5.1v5.8L5.1 15h5.8l4.1-4.1V5.1L10.9 1z"
            ]
            []
        , path
            [ d "M7.002 11a1 1 0 1 1 2 0 1 1 0 0 1-2 0M7.1 4.995a.905.905 0 1 1 1.8 0l-.35 3.507a.552.552 0 0 1-1.1 0z"
            ]
            []
        ]
