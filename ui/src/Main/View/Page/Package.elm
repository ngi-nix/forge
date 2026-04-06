module Main.View.Page.Package exposing (..)

import Html exposing (Html, a, text)
import Html.Attributes exposing (attribute, class, href, style, title)
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Helpers.AppUrl exposing (..)
import Main.Helpers.Html exposing (..)
import Main.Helpers.Nix exposing (..)
import Main.Icons exposing (..)
import Main.Model exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Route as Route exposing (..)
import Main.Update exposing (..)
import Main.View.Page.App exposing (..)
import Main.View.Page.App.Run exposing (..)
import Main.View.Page.Recipe exposing (..)


viewPagePackageLink : Html Update
viewPagePackageLink =
    let
        onClickRoute =
            -- FixMe(correctness)
            Route_RecipeOptions
                { routeRecipeOptions_pattern = Just ""
                , routeRecipeOptions_page = 1
                , routeRecipeOptions_MaxResultsPerPage = 10
                , routeRecipeOptions_option = Nothing
                }
    in
    a
        [ href (onClickRoute |> Route.toString)
        , style "color" "inherit"
        , style "text-decoration" "none"
        , style "cursor" "pointer"
        , class "nav-link px-0"
        , title "View available packages"
        , attribute "aria-label" "View available packages"
        , onClick (Update_Route onClickRoute)
        ]
        [ text "Packages" ]
