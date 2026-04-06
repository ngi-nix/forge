module Main.View.Page.Recipe exposing (..)

import Html exposing (Html, a, code, div, h5, span, text)
import Html.Attributes exposing (attribute, class, href, id, style, title)
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
    let
        routeRecipeOptions =
            pageRecipeOptions.pageRecipeOptions_route

        routePagePrev =
            Route_RecipeOptions
                { routeRecipeOptions
                    | routeRecipeOptions_page = routeRecipeOptions.routeRecipeOptions_page - 1
                }

        routePageNext =
            Route_RecipeOptions
                { routeRecipeOptions
                    | routeRecipeOptions_page = routeRecipeOptions.routeRecipeOptions_page + 1
                }
    in
    div []
        [ div [ class "list-group" ]
            (model.model_RecipeOptions.modelRecipeOptions_filtered
                |> List.map (viewPageRecipeOption model pageRecipeOptions)
            )
        , div [ class "d-flex justify-content-center align-items-center" ]
            [ if 1 < routeRecipeOptions.routeRecipeOptions_page then
                Html.button
                    [ class "btn"
                    , onClick (Update_Route routePagePrev)
                    ]
                    [ text "Prev" ]

              else
                text ""
            , text (pageRecipeOptions.pageRecipeOptions_route.routeRecipeOptions_page |> String.fromInt)
            , text " / "
            , text (pageRecipeOptions.pageRecipeOptions_LastPage |> String.fromInt)
            , if routeRecipeOptions.routeRecipeOptions_page < pageRecipeOptions.pageRecipeOptions_LastPage then
                Html.button
                    [ class "btn"
                    , onClick (Update_Route routePageNext)
                    ]
                    [ text "Next" ]

              else
                text ""
            ]
        ]


viewPageRecipeOption : Model -> PageRecipeOptions -> ( NixName, NixModuleOption ) -> Html Update
viewPageRecipeOption _ pageRecipeOptions ( optionName, option ) =
    let
        routeRecipeOptions =
            pageRecipeOptions.pageRecipeOptions_route

        onClickRoute =
            Route_RecipeOptions
                { routeRecipeOptions
                    | routeRecipeOptions_option = Just optionName
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
        , class "nav-link px-0 fw-bold"
        , title "View available recipe options"
        , attribute "aria-label" "View available recipe options"
        , onClick (Update_Route onClickRoute)
        ]
        [ text "Options" ]
