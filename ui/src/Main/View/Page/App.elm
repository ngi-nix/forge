module Main.View.Page.App exposing (..)

import AppUrl
import Dict
import Html exposing (Html, a, button, div, h2, h4, h5, h6, hr, img, li, p, small, span, text, ul)
import Html.Attributes exposing (attribute, class, href, id, rel, src, style, tabindex, target)
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Helpers.AppUrl as AppUrl exposing (..)
import Main.Helpers.Html exposing (..)
import Main.Helpers.Markdown as Markdown
import Main.Helpers.Nix exposing (..)
import Main.Icons exposing (..)
import Main.Model exposing (..)
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
                , class "app-header-icon"
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
viewPageAppNgiGrants model pageApp =
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


viewPageAppSearch : Model -> Html Update
viewPageAppSearch model =
    div
        [ class "m-app-grid"
        ]
        (model.model_config.config_apps
            |> Dict.values
            |> (case model.model_search of
                    "" ->
                        identity

                    _ ->
                        List.filter
                            (\app ->
                                let
                                    -- Case Insensitive search
                                    model_search =
                                        String.toLower model.model_search

                                    app_name =
                                        String.toLower app.app_name

                                    app_description =
                                        String.toLower app.app_description

                                    name_matches =
                                        String.contains model_search app_name

                                    desc_matches =
                                        String.contains model_search app_description
                                in
                                name_matches || desc_matches
                            )
               )
            |> List.map (viewPageAppSearchApp model)
        )


viewPageAppSearchApp : Model -> App -> Html Update
viewPageAppSearchApp _ app =
    a
        [ href (Route_App { defaultRouteApp | routeApp_name = app.app_name } |> Route.toString)
        , class "card m-app-card shadow-sm p-3"
        , style "text-decoration" "none"
        , onClick (Update_Route (Route_App { defaultRouteApp | routeApp_name = app.app_name }))
        ]
        [ div
            [ class "w-100"
            , style "display" "flex"
            , style "align-items" "center"
            , style "gap" "12px"
            ]
            [ img
                [ src (getAppIconPath app.app_name)
                , class "app-card-icon"
                , attribute "alt" (app.app_name ++ " icon")
                ]
                []
            , h5 [ class "mb-10" ] [ text app.app_name ]
            ]
        , p
            [ class "mb-1"
            ]
            [ text app.app_description ]
        , p
            [ class "mb-1"
            ]
            [ small []
                (List.concat
                    [ if app.app_programs.enable then
                        [ span [ class "badge bg-secondary me-1" ] [ text "shell" ] ]

                      else
                        []
                    , if app.app_services.appServices_runtimes.appServicesRuntimes_container.enable then
                        [ span [ class "badge bg-secondary me-1" ] [ text "container" ] ]

                      else
                        []
                    , if app.app_services.appServices_runtimes.appServicesRuntimes_nixos.enable then
                        [ span [ class "badge bg-secondary me-1" ] [ text "vm" ] ]

                      else
                        []
                    ]
                )
            ]
        ]
