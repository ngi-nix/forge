module Main.View.Page.App exposing (..)

import Dict
import Html exposing (Html, a, button, div, h2, h4, h6, hr, img, li, p, small, text, ul)
import Html.Attributes exposing (attribute, class, href, id, rel, src, style, tabindex, target)
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Helpers.AppUrl exposing (..)
import Main.Helpers.Html exposing (..)
import Main.Helpers.Markdown as Markdown
import Main.Helpers.Nix exposing (..)
import Main.Icons exposing (..)
import Main.Model exposing (..)
import Main.Model.Page exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Route as Route exposing (..)
import Main.Update exposing (..)
import Main.View.Page.App.Run exposing (..)


viewPageApp : Model -> PageApp -> Html Update
viewPageApp model pageApp =
    div [ class "container" ]
        [ div [ class "row" ]
            [ div
                [ class "col-12 col-lg-9" ]
                [ viewPageAppHeader model pageApp
                , viewPageAppDescription model pageApp
                , viewPageAppRun model pageApp
                ]
            , div
                [ class "col-12 col-lg-3 order-lg-first" ]
                [ viewPageAppResources model pageApp
                , viewPageAppNgiGrants model pageApp
                ]
            ]
        ]


viewPageAppHeader : Model -> PageApp -> Html Update
viewPageAppHeader _ pageApp =
    div
        [ style "display" "flex"
        , style "justify-content" "space-between"
        , style "align-items" "center"
        , class "my-4 mb-4"
        ]
        [ div
            [ style "display" "flex"
            , style "align-items" "center"
            , style "gap" "16px"
            ]
            [ img
                [ src (getAppIconPath pageApp.pageApp_route.routeApp_name)
                , class "item-header-icon"
                , attribute "loading" "lazy"
                , attribute "alt" (pageApp.pageApp_route.routeApp_name ++ " icon")
                ]
                []
            , h2
                [ class "mb-0 fw-bold"
                , style "margin" "0"
                ]
                [ text pageApp.pageApp_route.routeApp_name
                ]
            ]
        , button
            [ class "btn"
            , case pageApp.pageApp_runtime of
                Nothing ->
                    class "btn-secondary"

                Just _ ->
                    class "btn-success"
            , let
                route =
                    pageApp.pageApp_route
              in
              onClick (Update_RouteWithoutHistory (Route_App { route | routeApp_runShown = True }))
            ]
            [ text "Run" ]
        ]


viewPageAppDescription : Model -> PageApp -> Html Update
viewPageAppDescription model pageApp =
    div []
        [ p [ class "lead" ] [ text pageApp.pageApp_app.app_description ]
        , viewPageAppUsage model pageApp
        ]


viewPageAppUsage : Model -> PageApp -> Html Update
viewPageAppUsage _ pageApp =
    if not (String.isEmpty pageApp.pageApp_app.app_usage) then
        div [ id "usage", class "mt-4" ]
            [ hr [] []
            , h4 [ class "mb-3" ] [ text "Usage Instructions" ]
            , div [ class "markdown-content" ]
                (pageApp.pageApp_app.app_usage
                    |> Markdown.render
                )
            ]

    else
        text ""


viewPageAppResources : Model -> PageApp -> Html Update
viewPageAppResources model pageApp =
    let
        routeApp =
            pageApp.pageApp_route
    in
    div
        [ class "box-container target-highlight mb-3"
        , id "resources"
        , tabindex -1
        ]
        [ h6
            [ class "mt-3 mb-3 ms-2"
            ]
            [ text "Resources"
            , a
                [ class "anchor-link"
                , href
                    ({ routeApp | routeApp_focus = Just RouteAppFocus_Resources }
                        |> Route_App
                        |> Route.toString
                    )
                ]
                []
            ]
        , ul [ class "", style "padding-left" "10px" ]
            (List.concat
                [ viewPageAppResourcesItem "Homepage" pageApp.pageApp_app.app_links.appLinks_website
                , viewPageAppResourcesItem "Documentation" pageApp.pageApp_app.app_links.appLinks_docs
                , viewPageAppResourcesItem "Source Repository" pageApp.pageApp_app.app_links.appLinks_source
                , viewPageAppResourcesItem "Forge Recipe" (Just (showAppRecipeLink model pageApp.pageApp_app))
                ]
            )
        ]


viewPageAppResourcesItem : String -> Maybe String -> List (Html msg)
viewPageAppResourcesItem name value =
    case value of
        Nothing ->
            []

        Just url ->
            [ li [ class "list-group-item bg-transparent px-0 mb-3" ]
                [ a
                    [ href url
                    , target "_blank"
                    , rel "noopener"
                    ]
                    [ text name ]
                ]
            ]


showAppRecipeLink : Model -> App -> String
showAppRecipeLink model app =
    String.join "/"
        [ model.model_config.config_repository |> showNixUrl
        , "blob/" ++ commit
        , model.model_config.config_recipe.configRecipe_apps
        , app |> app_output
        , "recipe.nix"
        ]


viewPageAppNgiGrants : Model -> PageApp -> Html msg
viewPageAppNgiGrants _ pageApp =
    let
        routeApp =
            pageApp.pageApp_route
    in
    if
        pageApp.pageApp_app.app_ngi.ngi_grants
            |> Dict.values
            |> List.concat
            |> List.isEmpty
    then
        text ""

    else
        div
            [ class "box-container target-highlight mb-3"
            , id "grants"
            , tabindex -1
            ]
            [ h6
                [ class "mt-3 mb-3 ms-2"
                ]
                [ text "NGI Grants"
                , a
                    [ class "anchor-link"
                    , href
                        ({ routeApp | routeApp_focus = Just RouteAppFocus_Grants }
                            |> Route_App
                            |> Route.toString
                        )
                    ]
                    []
                ]
            , div []
                (pageApp.pageApp_app.app_ngi.ngi_grants
                    |> Dict.toList
                    |> List.map viewPageGrantCategory
                )
            ]


viewPageGrantCategory : ( String, NgiSubgrants ) -> Html msg
viewPageGrantCategory ( grant, subgrants ) =
    if List.isEmpty subgrants then
        text ""

    else
        div [ class "container row mb-1" ]
            [ small [ class "col-6" ] [ text grant ]
            , ul [ class "col" ]
                (List.map
                    (\subgrant ->
                        li [ class "list-group-item bg-transparent mb-1" ]
                            [ a
                                [ href ("https://nlnet.nl/project/" ++ subgrant ++ "/")
                                , target "_blank"
                                , rel "noopener noreferrer"
                                ]
                                [ text subgrant ]
                            ]
                    )
                    subgrants
                )
            ]


getAppIconPath : AppName -> String
getAppIconPath name =
    "resources/apps/" ++ name ++ "/icon.svg"


defaultAppIconPath : String
defaultAppIconPath =
    "resources/apps/app-icon.svg"
