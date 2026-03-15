module Main.Route exposing (..)

import AppUrl exposing (AppUrl)
import Dict
import Json.Decode
import Json.Encode
import List.Extra as List
import Main.Config.App


type Route
    = Route_Search String
    | Route_App Main.Config.App.AppName


type RouteError
    = RouteError_Parsing String
    | RouteError_Unknown AppUrl


showRouteError : RouteError -> String
showRouteError err =
    case err of
        RouteError_Parsing s ->
            "RouteError_Parsing: " ++ s

        RouteError_Unknown url ->
            "RouteError_Unknown: " ++ AppUrl.toString url


fromAppUrl : AppUrl -> Result RouteError Route
fromAppUrl url =
    case url.path of
        [] ->
            Ok (Route_Search "")

        [ "app" ] ->
            case url.queryParameters |> Dict.get "q" |> Maybe.andThen List.uncons of
                Nothing ->
                    Ok (Route_Search "")

                Just ( q, _ ) ->
                    Ok (Route_Search q)

        [ "app", app ] ->
            case app |> Json.Encode.string |> Json.Decode.decodeValue Main.Config.App.decodeAppName of
                Err e ->
                    Err (RouteError_Parsing (Json.Decode.errorToString e))

                Ok n ->
                    Ok (Route_App n)

        _ ->
            Err (RouteError_Unknown url)


toAppUrl : Route -> AppUrl
toAppUrl route =
    case route of
        Route_Search pattern ->
            case pattern of
                "" ->
                    [ "" ] |> AppUrl.fromPath

                _ ->
                    { path = [ "app" ]
                    , queryParameters = [ ( "q", [ pattern ] ) ] |> Dict.fromList
                    , fragment = Nothing
                    }

        Route_App name ->
            [ "app", name ] |> AppUrl.fromPath


toString : Route -> String
toString =
    toAppUrl >> AppUrl.toString
