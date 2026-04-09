module Main.View.Page.Recipe exposing (..)

import Html exposing (Html, a, button, code, div, h5, span, text)
import Html.Attributes exposing (attribute, class, disabled, href, id, style, title)
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Helpers.AppUrl exposing (..)
import Main.Helpers.Html exposing (..)
import Main.Helpers.Markdown as Markdown
import Main.Helpers.Nix exposing (..)
import Main.Icons exposing (..)
import Main.Model exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Route as Route exposing (..)
import Main.Update exposing (..)
import Main.View.Page.App exposing (..)


viewPageRecipeOptions : Model -> PageRecipeOptions -> Html Update
viewPageRecipeOptions model pageRecipeOptions =
    div []
        [ viewPageRecipePageNavigators pageRecipeOptions
        , div [ class "list-group" ]
            (model.model_RecipeOptions.modelRecipeOptions_filtered
                |> List.map (viewPageRecipeOption model pageRecipeOptions)
            )
        , viewPageRecipePageNavigators pageRecipeOptions
        ]


viewPageRecipeOption : Model -> PageRecipeOptions -> ( NixName, NixModuleOption ) -> Html Update
viewPageRecipeOption _ pageRecipeOptions ( optionName, option ) =
    let
        routeRecipeOptions =
            pageRecipeOptions.pageRecipeOptions_route

        onClickRoute =
            Route_RecipeOptions
                { routeRecipeOptions
                    | routeRecipeOptions_focus = Just <| RouteRecipeOptionsFocus_Option optionName
                }
    in
    a
        [ class "recipe-option list-group-item list-group-item-action flex-column align-items-start"
        , href (onClickRoute |> Route.toString)
        , id optionName
        , onClick (Update_Route onClickRoute)
        ]
        [ div [ class "d-flex w-100 justify-content-between" ]
            [ h5
                [ class "mb-1"
                ]
                [ code [] [ text optionName ]
                ]
            ]
        , div []
            [ span [ class "fw-bold" ] [ text "Type: " ]
            , code [] [ text option.nixModuleOption_type ]
            ]
        , div []
            [ span [ class "fw-bold" ] [ text "Description: " ]
            , div []
                (option.nixModuleOption_description
                    |> Markdown.render
                )
            ]
        ]


viewRecipeOptionsLink : Html Update
viewRecipeOptionsLink =
    let
        onClickRoute =
            Route_RecipeOptions
                defaultRouteRecipeOptions
    in
    a
        [ href (onClickRoute |> Route.toString)
        , style "color" "inherit"
        , style "text-decoration" "none"
        , style "cursor" "pointer"
        , class "nav-link px-0 fw-bold"
        , title "View available recipe options"
        , attribute "aria-label" "View available recipe options"
        , onClick (Update_Route onClickRoute)
        ]
        [ text "Options" ]


viewPageRecipePageNavigators : PageRecipeOptions -> Html Update
viewPageRecipePageNavigators pageRecipeOptions =
    let
        routeRecipeOptions =
            pageRecipeOptions.pageRecipeOptions_route

        routePagePrev =
            Route_RecipeOptions
                { routeRecipeOptions
                    | routeRecipeOptions_page = Just (pageRecipeOptions.pageRecipeOptions_page - 1)
                }

        routePageNext =
            Route_RecipeOptions
                { routeRecipeOptions
                    | routeRecipeOptions_page = Just (pageRecipeOptions.pageRecipeOptions_page + 1)
                }
    in
    div [ class "d-flex justify-content-center align-items-center my-2" ]
        [ if 1 < pageRecipeOptions.pageRecipeOptions_page then
            button
                [ class "btn me-2 focus-ring"
                , onClick (Update_Route routePagePrev)
                ]
                [ text "Prev" ]

          else
            button
                [ class "btn me-2 border-0"
                , disabled True
                ]
                [ text "Prev" ]
        , span
            [ style "width" "2rem"
            , style "text-align" "center"
            ]
            [ text (pageRecipeOptions.pageRecipeOptions_page |> String.fromInt) ]
        , text "/"
        , span
            [ style "width" "2rem"
            , style "text-align" "center"
            ]
            [ text (pageRecipeOptions.pageRecipeOptions_LastPage |> String.fromInt) ]
        , if pageRecipeOptions.pageRecipeOptions_page < pageRecipeOptions.pageRecipeOptions_LastPage then
            button
                [ class "btn ms-2 focus-ring"
                , onClick (Update_Route routePageNext)
                ]
                [ text "Next" ]

          else
            button
                [ class "btn ms-2 border-0"
                , disabled True
                ]
                [ text "Next" ]
        ]
