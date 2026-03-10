module NixForge.Select.Update exposing (..)

import Http
import List.Extra as List
import NixForge.Clipboard exposing (copyToClipboard)
import NixForge.Config exposing (..)
import NixForge.Config.App exposing (..)
import NixForge.Config.Package exposing (..)
import NixForge.Http as Http
import NixForge.Output exposing (..)
import NixForge.Route exposing (..)
import NixForge.Select.Model exposing (..)


type UpdateSelect
    = UpdateSelect_App App
    | UpdateSelect_CopyCode String
    | UpdateSelect_GetConfig (Result Http.Error Config)
    | UpdateSelect_Package Package
    | UpdateSelect_Route Route
    | UpdateSelect_Search String
    | UpdateSelect_Output OutputCategory


updateSelect : UpdateSelect -> ModelSelect -> Updater ModelSelect UpdateSelect
updateSelect msg model =
    case msg of
        UpdateSelect_App app ->
            Updater_Model
                { model
                    | selectedApp = Just app
                    , selectedOutput = OutputCategory_Applications
                }

        UpdateSelect_CopyCode code ->
            Updater_Cmd
                ( model, copyToClipboard code )

        UpdateSelect_GetConfig res ->
            case res of
                Ok config ->
                    Updater_Model
                        { model
                            | repositoryUrl = config.repositoryUrl
                            , recipeDirPackages = config.recipeDirs.packages
                            , recipeDirApps = config.recipeDirs.apps
                            , apps = config.apps
                            , packages = config.packages
                            , error = Nothing
                        }

                Err err ->
                    Updater_Model
                        { model | error = Just (Http.errorToString err) }

        UpdateSelect_Route route ->
            case route of
                Route_Select r ->
                    Updater_Cmd (routeSelect r model)

        UpdateSelect_Package pkg ->
            Updater_Model
                { model
                    | selectedPackage = Just pkg
                    , selectedOutput = OutputCategory_Packages
                }

        UpdateSelect_Search string ->
            Updater_Model
                { model | searchString = string }

        UpdateSelect_Output output ->
            Updater_Model
                { model | selectedOutput = output }


routeSelect : RouteSelect -> ModelSelect -> ( ModelSelect, Cmd UpdateSelect )
routeSelect rt model =
    case rt of
        RouteSelect_List ->
            ( { model
                | selectedOutput = OutputCategory_Packages
              }
            , Cmd.none
            )

        RouteSelect_Package (PackageName pkgName) ->
            ( { model
                | selectedPackage =
                    model.packages
                        |> List.find (\pkg -> pkg.name == pkgName)
                , selectedOutput = OutputCategory_Packages
              }
            , Cmd.none
            )
