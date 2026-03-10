module AppStore.Select.Update exposing (..)

import AppStore.Clipboard exposing (copyToClipboard)
import AppStore.Config exposing (..)
import AppStore.Config.App exposing (..)
import AppStore.Http as Http
import AppStore.Route exposing (..)
import AppStore.Select.Model exposing (..)
import Dict
import Http


type UpdateSelect
    = UpdateSelect_App App
    | UpdateSelect_CopyCode String
    | UpdateSelect_GetConfig (Result Http.Error Config)
    | UpdateSelect_Route Route
    | UpdateSelect_Search String


updateSelect : UpdateSelect -> ModelSelect -> Updater ModelSelect UpdateSelect
updateSelect msg model =
    case msg of
        UpdateSelect_App app ->
            Updater_Model { model | selectedApp = Just app }

        UpdateSelect_CopyCode code ->
            Updater_Cmd
                ( model, copyToClipboard code )

        UpdateSelect_GetConfig res ->
            case res of
                Ok config ->
                    Updater_Model
                        { model
                            | repositoryUrl = config.repositoryUrl
                            , recipeDirApps = config.recipeDirs.apps
                            , apps = config.apps
                            , error = Nothing
                        }

                Err err ->
                    Updater_Model
                        { model | error = Just (Http.errorToString err) }

        UpdateSelect_Route route ->
            case route of
                Route_Select r ->
                    Updater_Cmd (routeSelect r model)

        UpdateSelect_Search string ->
            Updater_Model
                { model | searchString = string }


routeSelect : RouteSelect -> ModelSelect -> ( ModelSelect, Cmd UpdateSelect )
routeSelect rt model =
    case rt of
        RouteSelect_List ->
            ( { model | selectedApp = Nothing }
            , Cmd.none
            )

        RouteSelect_App (AppName pkgName) ->
            ( { model | selectedApp = model.apps |> Dict.get pkgName }
            , Cmd.none
            )
