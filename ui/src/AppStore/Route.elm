module AppStore.Route exposing (..)

import AppStore.Config.App as App
import AppUrl exposing (AppUrl)


type Updater model cmd
    = Updater_Route Route
    | Updater_Model model
    | Updater_Cmd ( model, Cmd cmd )


type Route
    = Route_Select RouteSelect


type RouteSelect
    = RouteSelect_List
    | RouteSelect_App App.AppName


type Slug
    = Slug String


fromAppUrl : AppUrl -> Maybe Route
fromAppUrl url =
    case url.path of
        [] ->
            Just (Route_Select RouteSelect_List)

        [ "app", app ] ->
            case App.appName app of
                Just name ->
                    Just (Route_Select (RouteSelect_App name))

                Nothing ->
                    Nothing

        _ ->
            Nothing


toAppUrl : Route -> AppUrl
toAppUrl page =
    case page of
        Route_Select rt ->
            case rt of
                RouteSelect_List ->
                    AppUrl.fromPath []

                RouteSelect_App (App.AppName name) ->
                    AppUrl.fromPath [ "app", name ]


toString : Route -> String
toString =
    toAppUrl >> AppUrl.toString
