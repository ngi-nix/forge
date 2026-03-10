module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html exposing (Html)
import NixForge.Config exposing (..)
import NixForge.Config.App exposing (..)
import NixForge.Config.Package exposing (..)
import NixForge.Model exposing (..)
import NixForge.Route exposing (..)
import NixForge.Select exposing (..)
import NixForge.Select.Model exposing (..)
import NixForge.Select.Update exposing (..)
import NixForge.Select.View exposing (..)
import NixForge.Update exposing (..)
import Url exposing (Url)


main : Program () Model Update
main =
    Browser.application
        { init = init
        , view = \model -> { title = "Nix Forge", body = [ view model ] }
        , update = NixForge.Update.update
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
