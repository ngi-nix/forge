module Main exposing (main)

import AppStore.Config exposing (..)
import AppStore.Config.App exposing (..)
import AppStore.Model exposing (..)
import AppStore.Route exposing (..)
import AppStore.Select exposing (..)
import AppStore.Select.Model exposing (..)
import AppStore.Select.Update exposing (..)
import AppStore.Select.View exposing (..)
import AppStore.Update exposing (..)
import Browser
import Browser.Navigation as Nav
import Html exposing (Html)
import Url exposing (Url)


main : Program () Model Update
main =
    Browser.application
        { init = init
        , view = \model -> { title = "NGI Nix App Store", body = [ view model ] }
        , update = AppStore.Update.update
        , subscriptions = \_ -> Sub.none
        , onUrlRequest = Update_LinkClicked
        , onUrlChange = Update_UrlChange
        }


init : () -> Url -> Nav.Key -> ( Model, Cmd Update )
init inp url navKey =
    let
        ( modelSelect, updateSelect ) =
            initSelect inp
    in
    ( Model_Select modelSelect
    , Cmd.batch
        [ updateSelect |> Cmd.map Update_Select
        ]
    )


view : Model -> Html Update
view model =
    case model of
        Model_Select m ->
            m |> viewSelect |> Html.map Update_Select
