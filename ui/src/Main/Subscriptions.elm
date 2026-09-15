module Main.Subscriptions exposing (..)

import Browser.Events
import Json.Decode as Decode
import Main.Config.App exposing (..)
import Main.Model exposing (..)
import Main.Model.Page exposing (..)
import Main.Model.Route exposing (..)
import Main.Ports.Navigation
import Main.Update exposing (..)
import Main.Update.Types exposing (..)
import Navigation


subscriptions : Model -> Sub Update
subscriptions model =
    Sub.batch
        [ Navigation.onEvent Main.Ports.Navigation.onNavEvent Update_Navigation
        , case model.model_page of
            Page_App pageApp ->
                if pageApp.pageApp_route.routeApp_runShown then
                    Sub.none

                else
                    Browser.Events.onKeyDown decodeAmbientKeyPress

            _ ->
                Browser.Events.onKeyDown decodeAmbientKeyPress
        , case model.model_page of
            Page_App pageApp ->
                if pageApp.pageApp_route.routeApp_runShown || pageApp.pageApp_route.routeApp_iconShown then
                    Browser.Events.onKeyDown
                        (decodeEscapeKey
                            |> Decode.map
                                (\_ ->
                                    let
                                        route =
                                            pageApp.pageApp_route
                                    in
                                    Update_RouteWithoutHistory (Route_App { route | routeApp_runShown = False, routeApp_iconShown = False })
                                )
                        )

                else
                    Sub.none

            _ ->
                if model.model_appsCategoryDropdownOpen || model.model_appsSortDropdownOpen then
                    Browser.Events.onKeyDown
                        (decodeEscapeKey
                            |> Decode.map
                                (\_ ->
                                    if model.model_appsCategoryDropdownOpen && model.model_appsCategorySearch /= "" then
                                        Update_Chain
                                            [ Update_CategorySearch ""
                                            , Update_Blur "category-search-input"
                                            ]

                                    else
                                        Update_Chain
                                            [ if model.model_appsCategoryDropdownOpen then
                                                Update_ToggleAppsCategoryDropdown

                                              else
                                                Update_NoOp
                                            , if model.model_appsSortDropdownOpen then
                                                Update_ToggleAppsSortDropdown

                                              else
                                                Update_NoOp
                                            , Update_CategorySearch ""
                                            ]
                                )
                        )

                else
                    Sub.none
        ]


decodeEscapeKey : Decode.Decoder Bool
decodeEscapeKey =
    Decode.field "key" Decode.string
        |> Decode.andThen
            (\key ->
                if key == "Escape" then
                    Decode.succeed False

                else
                    Decode.fail "Not escape"
            )


decodeAmbientKeyPress : Decode.Decoder Update
decodeAmbientKeyPress =
    Decode.map3
        (\key node modifier ->
            Update_AmbientKeyPress
                { key = key
                , focusedTyping =
                    List.member node
                        -- When typing into some actual input fields
                        [ "INPUT"
                        , "TEXTAREA"
                        , "SELECT"
                        ]
                , hasModifier = modifier
                }
        )
        (Decode.field "key" Decode.string)
        (Decode.at [ "target", "nodeName" ] Decode.string)
        (Decode.map3
            (\ctrl meta alt -> ctrl || meta || alt)
            (Decode.field "ctrlKey" Decode.bool)
            (Decode.field "metaKey" Decode.bool)
            (Decode.field "altKey" Decode.bool)
        )
