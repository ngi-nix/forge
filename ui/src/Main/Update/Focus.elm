module Main.Update.Focus exposing (..)

import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Helpers.Cmd as Cmd
import Main.Helpers.Nix exposing (..)
import Main.Model exposing (..)
import Main.Model.Error exposing (..)
import Main.Model.Page exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Model.Route exposing (..)
import Main.Ports.SmoothScroll exposing (..)
import Main.Update.Types exposing (..)


updateFocus : (a -> String) -> Maybe a -> Maybe a -> Model -> ( Model, Cmd Update )
updateFocus showFocus prevFocus nextFocus model =
    ( model
    , case nextFocus of
        Just focus ->
            if Just focus /= prevFocus then
                scrollToAndHighlight (focus |> showFocus)

            else
                Cmd.none

        Nothing ->
            Cmd.none
    )
