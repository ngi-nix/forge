module Main.Error exposing (..)

import AppUrl exposing (AppUrl)
import Http
import Main.Config.App exposing (..)


type Error
    = Error_App ErrorApp
    | Error_Http Http.Error
    | Error_Route ErrorRoute


type ErrorRoute
    = ErrorRoute_Parsing String
    | ErrorRoute_Unknown AppUrl


type ErrorApp
    = ErrorApp_NoSuchRuntime AppName AppRuntime
    | ErrorApp_NoRuntime AppName
    | ErrorApp_NotFound AppName
