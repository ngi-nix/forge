module Main.Error exposing (..)

import AppUrl exposing (AppUrl)
import Http
import Main.Config.App exposing (..)


type Error
    = Error_App ErrorApp
    | Error_Http Http.Error
    | Error_Route ErrorRoute


showErrorHttp : Http.Error -> String
showErrorHttp err =
    case err of
        Http.BadUrl s ->
            "Bad URL: " ++ s

        Http.Timeout ->
            "Request timed out"

        Http.NetworkError ->
            "Network error"

        Http.BadStatus s ->
            "Bad response: " ++ String.fromInt s

        Http.BadBody s ->
            "Bad body: " ++ s


type ErrorRoute
    = ErrorRoute_Parsing String
    | ErrorRoute_Unknown AppUrl


showError : Error -> String
showError err =
    case err of
        Error_App e ->
            showErrorApp e

        Error_Http e ->
            showErrorHttp e

        Error_Route e ->
            showErrorRoute e


showErrorRoute : ErrorRoute -> String
showErrorRoute err =
    case err of
        ErrorRoute_Parsing s ->
            "ErrorRoute_Parsing: " ++ s

        ErrorRoute_Unknown url ->
            "ErrorRoute_Unknown: " ++ AppUrl.toString url


type ErrorApp
    = ErrorApp_NoSuchRuntime AppRuntime
    | ErrorApp_NoRuntime AppName
    | ErrorApp_NotFound AppName


showErrorApp : ErrorApp -> String
showErrorApp err =
    String.concat <|
        case err of
            ErrorApp_NoSuchRuntime runtime ->
                [ "No such app runtime: "
                , runtime |> showAppRuntime
                , "."
                ]

            ErrorApp_NoRuntime appName ->
                [ "This application has no runtime: "
                , appName
                , "."
                ]

            ErrorApp_NotFound appName ->
                [ "No such app: "
                , appName
                , "."
                ]
