module Main.View.Page.Apps exposing (..)

import Dict
import Html exposing (Html, a, div, h5, img, p, small, span, text)
import Html.Attributes exposing (attribute, class, href, src, style)
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Helpers.AppUrl exposing (..)
import Main.Helpers.Html exposing (..)
import Main.Helpers.Nix exposing (..)
import Main.Icons exposing (..)
import Main.Model exposing (..)
import Main.Model.Page exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Route as Route exposing (..)
import Main.Update exposing (..)
import Main.View.Page.App exposing (..)


viewPageApps : Model -> PageApps -> Html Update
viewPageApps model _ =
    div
        [ class "m-item-grid"
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
            |> List.map (viewPageAppsApp model)
        )


viewPageAppsApp : Model -> App -> Html Update
viewPageAppsApp _ app =
    let
        onClickRoute =
            Route_App { defaultRouteApp | routeApp_name = app.app_name }
    in
    a
        [ href (onClickRoute |> Route.toString)
        , class "card m-item-card shadow-sm p-3"
        , style "text-decoration" "none"
        , onClick (Update_Route onClickRoute)
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
                    [ if app.app_services.appServices_runtimes.appServicesRuntimes_container.enable then
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
