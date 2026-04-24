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
import Main.View.Page.Recipe.Browser exposing (..)
import Main.View.Page.Recipe.Items exposing (..)
import Main.View.Pagination exposing (..)
import Set


type PageLayout
    = Layout_Mobile
    | Layout_Desktop


viewPageRecipeOptionsLink : PageLayout -> Html Update
viewPageRecipeOptionsLink layout =
    let
        onClickRoute =
            Route_RecipeOptions
                (case layout of
                    Layout_Desktop ->
                        defaultRouteRecipeOptions

                    Layout_Mobile ->
                        { defaultRouteRecipeOptions | routeRecipeOptions_unfolds = Set.empty }
                )
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
    let
        viewPaginationRecipeOptions =
            viewPagination
                PaginationVisibility_AlwaysVisible
                page.pageRecipeOptions_pagination
                (viewPageRecipeOptionsItem model page)
                (\modifyRoutePagination ->
                    let
                        route =
                            page.pageRecipeOptions_route
                    in
                    Route_RecipeOptions
                        { route
                            | routeRecipeOptions_pagination = route.routeRecipeOptions_pagination |> modifyRoutePagination
                            , routeRecipeOptions_focus = Nothing
                        }
                )
    in
    div
        [ class "row" ]
        [ div
            [ class "col-12 col-md-6 col-lg-5 col-xl-4 col-xxl-3-5"
            , style "margin-top" "calc(36px + 1em)"
            ]
            [ viewPageRecipeOptionsBrowser model page ]
        , div [ class "col-12 col-md-6 col-lg-7 col-xl-8 col-xxl-8-5" ]
            [ viewPaginationRecipeOptions ]
        ]
