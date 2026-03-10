module NixForge.Update exposing (..)

import Browser
import NixForge.Config exposing (..)
import NixForge.Config.App exposing (..)
import NixForge.Config.Package exposing (..)
import NixForge.Model exposing (..)
import NixForge.Route exposing (..)
import NixForge.Select exposing (..)
import NixForge.Select.Model exposing (..)
import NixForge.Select.Update exposing (..)
import Url


type Update
    = Update_Select UpdateSelect
    | Update_UrlChange Url.Url
    | Update_LinkClicked Browser.UrlRequest


update : Update -> Model -> ( Model, Cmd Update )
update upd currentModel =
    case ( upd, currentModel ) of
        ( Update_Select up, Model_Select currentModelSelect ) ->
            case updateSelect up currentModelSelect of
                Updater_Model newModel ->
                    ( Model_Select newModel, Cmd.none )

                Updater_Route newRoute ->
                    initRoute newRoute

                Updater_Cmd ( newModel, newCmd ) ->
                    ( Model_Select newModel, Cmd.map Update_Select newCmd )

        _ ->
            ( currentModel, Cmd.none )


initRoute : Route -> ( Model, Cmd Update )
initRoute route =
    case route of
        Route_Select rt ->
            case initSelect () of
                ( initModel, initCmd ) ->
                    case routeSelect rt initModel of
                        ( newModel, newCmd ) ->
                            ( Model_Select newModel, [ Cmd.map Update_Select initCmd, Cmd.map Update_Select newCmd ] |> Cmd.batch )
