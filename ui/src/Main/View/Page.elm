module Main.View.Page exposing (..)

import Html exposing (Html)
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Helpers.Html exposing (..)
import Main.Helpers.Nix exposing (..)
import Main.Icons exposing (..)
import Main.Model exposing (..)
import Main.Model.Page exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Model.Route exposing (..)
import Main.Update exposing (..)
import Main.Update.Types exposing (..)
import Main.View.Error exposing (..)
import Main.View.Page.App exposing (..)
import Main.View.Page.Apps exposing (..)
import Main.View.Page.Pkgs exposing (..)
import Main.View.Page.Recipe exposing (..)


viewPage : Model -> Html Update
viewPage model =
    case model.model_page of
        Page_App pageApp ->
            viewPageApp model pageApp

        Page_Apps pageApps ->
            viewPageApps model pageApps

        Page_Pkgs pagePkgs ->
            viewPagePkgs model pagePkgs

        Page_RecipeOptions pageRecipeOptions ->
            viewPageRecipeOptions model pageRecipeOptions
