module Main.View.Page.Recipe.Items exposing (viewPageRecipeOptionsItems)

import Html exposing (Html, a, code, div, h5, span, text)
import Html.Attributes exposing (attribute, class, href, id)
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Helpers.Html exposing (..)
import Main.Helpers.Markdown as Markdown
import Main.Helpers.Nix exposing (..)
import Main.Icons exposing (..)
import Main.Model exposing (..)
import Main.Model.Page exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Model.Route exposing (..)
import Main.Update exposing (..)
import Main.Update.Route.Recipe exposing (..)
import Main.Update.Types exposing (..)
import Main.View.Nix exposing (..)
import Main.View.Page.App exposing (..)
import Main.View.Pagination exposing (..)


viewPageRecipeOptionsItems : Model -> PageRecipeOptions -> Html Update
viewPageRecipeOptionsItems model page =
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


viewPageRecipeOptionsItem : Model -> PageRecipeOptions -> ( NixPath, NixModuleOption ) -> Html Update
viewPageRecipeOptionsItem _ page ( optionPath, option ) =
    let
        routeRecipeOptions =
            page.pageRecipeOptions_route

        optionName =
            optionPath |> joinNixPath

        routeItem =
            Route_RecipeOptions
                { routeRecipeOptions
                    | routeRecipeOptions_focus = Just <| RouteRecipeOptionsFocus_Option optionPath
                }
    in
    a
        [ class "list-item list-group-item list-group-item-action flex-column align-items-start"
        , href (routeItem |> routeToString)
        , attribute "data-testid" "option-result"
        , id optionName
        , onClick (Update_Route routeItem)
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
                [ option.nixModuleOption_description
                    |> Markdown.render
                ]
            ]
        ]
