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
                if pageApp.pageApp_route.routeApp_runShown || pageApp.pageApp_route.routeApp_deployShown || pageApp.pageApp_route.routeApp_screenshotShown /= Nothing then
                    Sub.none

                else
                    Browser.Events.onKeyDown decodeAmbientKeyPress

            _ ->
                Browser.Events.onKeyDown decodeAmbientKeyPress
        , case model.model_page of
            Page_App pageApp ->
                if pageApp.pageApp_route.routeApp_runShown || pageApp.pageApp_route.routeApp_deployShown || pageApp.pageApp_route.routeApp_iconShown then
                    Browser.Events.onKeyDown
                        (decodeEscapeKey
                            |> Decode.map
                                (\_ ->
                                    let
                                        route =
                                            pageApp.pageApp_route
                                    in
                                    Update_RouteWithoutHistory (Route_App { route | routeApp_runShown = False, routeApp_deployShown = False, routeApp_iconShown = False })
                                )
                        )

                else
                    case pageApp.pageApp_route.routeApp_screenshotShown of
                        Just index ->
                            Browser.Events.onKeyDown (decodeScreenshotKey pageApp index)

                        Nothing ->
                            Sub.none

            _ ->
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


{-| The Escape key closes the screenshot modal, and the arrow keys show the previous or the next screenshot.
-}
decodeScreenshotKey : PageApp -> Int -> Decode.Decoder Update
decodeScreenshotKey pageApp index =
    let
        route =
            pageApp.pageApp_route

        count =
            List.length pageApp.pageApp_app.app_screenshots

        show screenshot =
            Decode.succeed (Update_RouteWithoutHistory (Route_App { route | routeApp_screenshotShown = screenshot }))
    in
    Decode.field "key" Decode.string
        |> Decode.andThen
            (\key ->
                case key of
                    "Escape" ->
                        show Nothing

                    "ArrowLeft" ->
                        show (Just (modBy count (index - 1)))

                    "ArrowRight" ->
                        show (Just (modBy count (index + 1)))

                    _ ->
                        Decode.fail "Not a screenshot key"
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
