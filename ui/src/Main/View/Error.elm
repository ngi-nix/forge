module Main.View.Error exposing (..)

import AppUrl
import Html exposing (Html, code, div, span, text)
import Html.Attributes exposing (class)
import Http
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Helpers.AppUrl exposing (..)
import Main.Helpers.Html exposing (..)
import Main.Helpers.Nix exposing (..)
import Main.Icons exposing (..)
import Main.Model exposing (..)
import Main.Model.Error exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Model.Route exposing (..)
import Main.Update exposing (..)
import Main.Update.Types exposing (..)
import Main.View.Page.App exposing (..)
import Main.View.Page.Recipe exposing (..)


viewErrors : Model -> Html Update
viewErrors model =
    div []
        (model.model_errors
            |> List.map
                (\error ->
                    div [ class "alert alert-danger" ]
                        [ text "Error: "
                        , viewError error
                        ]
                )
        )


viewError : Error -> Html Update
viewError err =
    case err of
        Error_App e ->
            viewErrorApp e

        Error_Http e ->
            viewErrorHttp e

        Error_Package e ->
            viewErrorPackage e

        Error_Route e ->
            viewErrorRoute e


viewErrorHttp : Http.Error -> Html Update
viewErrorHttp err =
    span [] <|
        case err of
            Http.BadUrl s ->
                [ text "bad URL: "
                , text s
                ]

            Http.Timeout ->
                [ text "request timed out" ]

            Http.NetworkError ->
                [ text "network error" ]

            Http.BadStatus s ->
                [ text "bad response: "
                , text (s |> String.fromInt)
                ]

            Http.BadBody s ->
                [ text "bad body: "
                , text s
                ]


viewErrorRoute : ErrorRoute -> Html Update
viewErrorRoute err =
    span [] <|
        case err of
            ErrorRoute_Parsing s ->
                [ text "ErrorRoute_Parsing: "
                , text s
                ]

            ErrorRoute_Unknown url ->
                [ text "ErrorRoute_Unknown: "
                , code [] [ text (url |> AppUrl.toString) ]
                ]


viewErrorApp : ErrorApp -> Html Update
viewErrorApp err =
    span [] <|
        case err of
            ErrorApp_NoSuchRuntime appName runtime ->
                [ text "no "
                , code [] [ text (runtime |> showAppRuntime) ]
                , text " runtime enabled in the recipe of the application "
                , code [] [ text appName ]
                ]

            ErrorApp_NoRuntime appName ->
                [ text "no runtime enabled in the recipe of the application "
                , code [] [ text appName ]
                ]

            ErrorApp_NotFound appName ->
                [ text "no such application: "
                , code [] [ text appName ]
                ]


viewErrorPackage : ErrorPackage -> Html Update
viewErrorPackage err =
    span [] <|
        case err of
            ErrorPackage_NotFound packageName ->
                [ text "no such package: "
                , text packageName
                ]
