module Main.View.Page.Recipe exposing (..)

import Html exposing (Html, a, div, text)
import Html.Attributes exposing (attribute, class, href, style, title)
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
import Main.View.Page.App exposing (..)
import Main.View.Page.Recipe.Items exposing (..)
import Main.View.Page.Recipe.Nav exposing (..)
import Main.View.Pagination exposing (..)


viewPageRecipeOptionsLink : Html Update
viewPageRecipeOptionsLink =
    let
        onClickRoute =
            Route_RecipeOptions
                defaultRouteRecipeOptions
    in
    a
        [ href (onClickRoute |> routeToString)
        , style "color" "inherit"
        , style "text-decoration" "none"
        , style "cursor" "pointer"
        , class "nav-link px-0 fw-bold"
        , title "View available recipe options"
        , attribute "aria-label" "View available recipe options"
        , onClick (Update_Route onClickRoute)
        ]
        [ text "Options" ]


viewPageRecipeOptions : Model -> PageRecipeOptions -> Html Update
viewPageRecipeOptions model page =
    div
        [ style "display" "grid"
        , style "grid-template-columns" "1fr 4fr"
        , style "gap" "0rem 1rem"
        ]
        [ viewPageRecipeOptionsNav model page
        , viewPageRecipeOptionsItems model page
        ]
