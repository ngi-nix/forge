module Main.View.Page.App exposing (..)

import Dict
import Html exposing (Html, a, button, div, figcaption, figure, h2, h4, h6, hr, img, li, p, small, span, text, ul)
import Html.Attributes exposing (alt, attribute, class, href, id, rel, src, style, tabindex, target, title, type_)
import Html.Events exposing (stopPropagationOn)
import Json.Decode as Decode
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
import Main.Update.Types exposing (..)
import Main.View.Page.App.Deploy exposing (..)
import Main.View.Page.App.Run exposing (..)


viewPageApp : Model -> PageApp -> Html Update
viewPageApp model pageApp =
    div [ class "container" ]
        [ div [ class "row" ]
            [ div
                [ class "col-12 col-lg-9" ]
                [ viewPageAppFeedback model
                , viewPageAppHeader model pageApp
                , viewPageAppDescription model pageApp
                , viewPageAppRun model pageApp
                , viewPageAppDeploy model pageApp
                , viewPageAppIconModal model pageApp
                , viewPageAppScreenshotModal model pageApp
                ]
            , div
                [ class "col-12 col-lg-3 order-lg-first" ]
                [ viewPageAppResources model pageApp
                , viewPageAppNgiGrants model pageApp
                , viewPageAppConfiguration model pageApp
                , viewPageAppMaintainers model pageApp
                ]
            ]
        ]


viewPageAppHeader : Model -> PageApp -> Html Update
viewPageAppHeader _ pageApp =
    let
        routeApp =
            pageApp.pageApp_route

        onClickIcon =
            Route_App { routeApp | routeApp_iconShown = True }
    in
    -- On small screens, center the app icon, the app name and the buttons
    -- under each other.
    div
        [ class "d-flex flex-column flex-sm-row justify-content-between align-items-center gap-3"
        , class "my-4 mb-4"
        ]
        [ div
            [ class "d-flex flex-column flex-sm-row align-items-center text-center text-sm-start"
            , style "gap" "16px"
            ]
            [ (if pageApp.pageApp_app.app_hasIcon then
                img

               else
                Html.node "avatar-icon"
              )
                ([ class "item-header-icon"
                 , attribute "alt" (pageApp.pageApp_app.app_displayName ++ " icon")
                 , style "cursor" "pointer"
                 , onClick (Update_RouteWithoutHistory onClickIcon)
                 , attribute "data-display-name" pageApp.pageApp_app.app_displayName
                 , attribute "data-app-name" pageApp.pageApp_route.routeApp_name
                 ]
                    ++ (if pageApp.pageApp_app.app_hasIcon then
                            [ src (getAppIconPath pageApp.pageApp_route.routeApp_name) ]

                        else
                            []
                       )
                )
                []
            , h2
                [ class "mb-0 fw-bold"
                , style "margin" "0"
                , attribute "data-testid" "app-title"
                ]
                [ text pageApp.pageApp_app.app_displayName
                ]
            ]
        , div [ class "d-flex gap-2" ]
            ([ button
                [ class "btn"
                , attribute "data-testid" "app-run-button"
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
                ++ (if pageApp.pageApp_app.app_services.appServices_runtimes.appServicesRuntimes_nixos.enable then
                        [ button
                            [ class "btn btn-success"
                            , attribute "data-testid" "app-deploy-button"
                            , let
                                route =
                                    pageApp.pageApp_route
                              in
                              onClick (Update_RouteWithoutHistory (Route_App { route | routeApp_deployShown = True }))
                            ]
                            [ text "Deploy" ]
                        ]

                    else
                        []
                   )
            )
        ]


viewPageAppFeedback : Model -> Html Update
viewPageAppFeedback model =
    if not model.model_askFeedback then
        text ""

    else
        div
            [ class "alert alert-info alert-dismissible mt-3 feedback-message"
            , attribute "data-testid" "feedback-message"
            ]
            [ text "Tried this app? We'd love to "
            , a
                [ href "https://cryptpad.ngi.nixos.org/form/#/2/form/view/3X1lzb3+XxsLUq-TygwGn-R3aHcvwuNo3L7Ya8Z1VWo/"
                , target "_blank"
                , rel "noopener"
                , class "alert-link"
                ]
                [ text "know how it went" ]
            , text "."
            , button
                [ class "btn-close"
                , attribute "aria-label" "Close"
                , onClick Update_DismissFeedback
                ]
                []
            ]


getAppDescription : PageApp -> String
getAppDescription pageApp =
    let
        app =
            pageApp.pageApp_app
    in
    if String.isEmpty app.app_longDescription then
        app.app_description

    else
        app.app_longDescription


viewPageAppDescription : Model -> PageApp -> Html Update
viewPageAppDescription model pageApp =
    div []
        [ p
            [ class "text-body-secondary"
            , attribute "data-testid" "app-description"
            ]
            [ div [ class "text-body-secondary" ]
                [ pageApp
                    |> getAppDescription
                    |> Markdown.render
                ]
            ]
        , viewPageAppScreenshots pageApp
        , viewPageAppUsage model pageApp
        ]


viewPageAppScreenshots : PageApp -> Html Update
viewPageAppScreenshots pageApp =
    let
        routeApp =
            pageApp.pageApp_route

        name =
            routeApp.routeApp_name

        screenshots =
            pageApp.pageApp_app.app_screenshots

        rowId =
            "screenshots-row"

        -- The row scrolls, thus it gets a button at each end:
        -- dragging the row or moving along it with the tab key
        -- is not visible at first look.
        scrollButton direction label icon =
            button
                [ type_ "button"
                , class "btn btn-outline-secondary btn-sm screenshots-scroll flex-shrink-0"
                , title label
                , attribute "aria-label" label
                , attribute "aria-controls" rowId
                , onClick (Update_ScrollRow rowId direction)
                ]
                [ icon ]

        scrollButtons direction label icon =
            if List.length screenshots > 1 then
                [ scrollButton direction label icon ]

            else
                []
    in
    if List.isEmpty screenshots then
        text ""

    else
        div [ id "screenshots", class "mt-4" ]
            [ hr [] []
            , h4 [ class "mb-3" ] [ text "Screenshots" ]
            , div [ class "d-flex align-items-center gap-2" ]
                (scrollButtons -1 "Show the previous screenshots" iconChevronLeft
                    ++ div
                        [ id rowId
                        , class "screenshots d-flex gap-3 overflow-auto pb-2"
                        , attribute "data-testid" "app-screenshots"
                        ]
                        (List.indexedMap
                            (\index screenshot ->
                                figure [ class "screenshot flex-shrink-0 mb-0" ]
                                    [ a
                                        [ href (getAppScreenshotPath name index)
                                        , onPlainClick (Update_RouteWithoutHistory (Route_App { routeApp | routeApp_screenshotShown = Just index }))
                                        ]
                                        [ img
                                            [ src (getAppScreenshotThumbnailPath name index)
                                            , alt screenshot.appScreenshot_caption
                                            , attribute "loading" "lazy"
                                            , class "rounded border"
                                            ]
                                            []
                                        ]
                                    , if String.isEmpty screenshot.appScreenshot_caption then
                                        text ""

                                      else
                                        figcaption [ class "small text-body-secondary mt-1" ]
                                            [ text screenshot.appScreenshot_caption ]
                                    ]
                            )
                            screenshots
                        )
                    :: scrollButtons 1 "Show the next screenshots" iconChevronRight
                )
            ]


viewPageAppScreenshotModal : Model -> PageApp -> Html Update
viewPageAppScreenshotModal _ pageApp =
    let
        routeApp =
            pageApp.pageApp_route

        name =
            routeApp.routeApp_name

        screenshots =
            pageApp.pageApp_app.app_screenshots

        count =
            List.length screenshots

        show index =
            Update_RouteWithoutHistory (Route_App { routeApp | routeApp_screenshotShown = index })

        navButton step label icon =
            if count > 1 then
                button
                    [ type_ "button"
                    , class "btn btn-dark rounded-circle flex-shrink-0 screenshot-modal-nav"
                    , title label
                    , attribute "aria-label" label
                    , onClickOnly (show (Maybe.map (\index -> modBy count (index + step)) routeApp.routeApp_screenshotShown))
                    ]
                    [ icon ]

            else
                text ""
    in
    case
        routeApp.routeApp_screenshotShown
            |> Maybe.andThen (\index -> List.drop index screenshots |> List.head |> Maybe.map (Tuple.pair index))
    of
        Nothing ->
            text ""

        Just ( index, screenshot ) ->
            div
                [ class "modal show screenshot-modal"
                , style "display" "block"
                , attribute "role" "dialog"
                , attribute "aria-modal" "true"
                , attribute "aria-label" "Screenshots"
                , attribute "data-testid" "screenshot-modal"
                , tabindex -1

                -- A click outside of the image and the buttons closes the modal.
                , onClick (show Nothing)
                ]
                [ div [ class "d-flex flex-column h-100 p-3 gap-2" ]
                    [ div [ class "d-flex align-items-center gap-3 text-white" ]
                        [ span [ class "me-auto", attribute "data-testid" "screenshot-modal-position" ]
                            [ text (String.fromInt (index + 1) ++ " / " ++ String.fromInt count) ]
                        , a
                            [ href (getAppScreenshotPath name index)
                            , target "_blank"
                            , rel "noopener"
                            , class "link-light small"
                            , onClickStopPropagation
                            ]
                            [ text "Open the image" ]
                        , button
                            [ type_ "button"
                            , class "btn-close btn-close-white opacity-100"
                            , attribute "aria-label" "Close"
                            , onClickOnly (show Nothing)
                            ]
                            []
                        ]
                    , div [ class "d-flex align-items-center justify-content-center gap-2 flex-grow-1 screenshot-modal-body" ]
                        [ navButton -1 "Show the previous screenshot" iconChevronLeft
                        , img
                            [ src (getAppScreenshotPath name index)
                            , alt screenshot.appScreenshot_caption
                            , class "rounded screenshot-modal-image"
                            , onClickOnly Update_NoOp
                            ]
                            []
                        , navButton 1 "Show the next screenshot" iconChevronRight
                        ]
                    , if String.isEmpty screenshot.appScreenshot_caption then
                        text ""

                      else
                        p [ class "text-center text-white mb-0" ]
                            [ text screenshot.appScreenshot_caption ]
                    ]
                ]


viewPageAppUsage : Model -> PageApp -> Html Update
viewPageAppUsage _ pageApp =
    if not (String.isEmpty pageApp.pageApp_app.app_usage) then
        div [ id "usage", class "mt-4" ]
            [ hr [] []
            , h4 [ class "mb-3" ] [ text "Usage Instructions" ]
            , div [ class "text-body-secondary" ]
                [ pageApp.pageApp_app.app_usage |> Markdown.render ]
            ]

    else
        text ""


viewBulletList : List (Html Update) -> Html Update
viewBulletList items =
    ul
        [ class "ms-2 mb-3"
        , style "list-style-type" "disc"
        , style "padding-left" "1.2em"
        ]
        items


viewPortList : List String -> Html Update
viewPortList ports =
    if List.isEmpty ports then
        text ""

    else
        ul
            [ class "ms-3 mb-1"
            , style "list-style-type" "none"
            , style "padding" "0px"
            ]
            (List.map
                (\p -> li [] [ small [ class "text-body-secondary" ] [ text (String.replace ":" " → " p) ] ])
                ports
            )


viewResource : ( String, AppResource ) -> Html Update
viewResource ( rname, resource ) =
    li []
        [ small [] [ text rname ]
        , viewPortList resource.appResource_ports
        ]


viewComponent : ( String, AppComponent ) -> Html Update
viewComponent ( cname, component ) =
    li []
        [ small [] [ text cname ]
        , viewPortList component.appComponent_ports
        ]


viewPageAppConfiguration : Model -> PageApp -> Html Update
viewPageAppConfiguration _ pageApp =
    let
        routeApp =
            pageApp.pageApp_route

        packageNames =
            getAppProgramPackageNames pageApp.pageApp_app.app_programs

        components =
            pageApp.pageApp_app.app_services.appServices_components

        resources =
            pageApp.pageApp_app.app_services.appServices_resources
    in
    div
        [ class "box-container target-highlight mb-3"
        , id (showRouteAppFocus RouteAppFocus_Configuration)
        , tabindex -1
        ]
        [ h6
            [ class "mt-3 mb-3 ms-2"
            ]
            [ text "Configuration"
            , a
                [ class "anchor-link"
                , href
                    ({ routeApp | routeApp_focus = Just RouteAppFocus_Configuration }
                        |> Route_App
                        |> routeToString
                    )
                ]
                []
            ]
        , if List.isEmpty packageNames then
            text ""

          else
            div []
                [ div [ class "ms-2 mb-1" ]
                    [ small [ class "text-body-secondary" ] [ text "Programs" ] ]
                , viewBulletList
                    (List.map (\n -> li [] [ small [] [ text n ] ]) packageNames)
                ]
        , if Dict.isEmpty components then
            text ""

          else
            div []
                [ div [ class "ms-2 mb-1" ]
                    [ small [ class "text-body-secondary" ] [ text "Services" ] ]
                , viewBulletList
                    (components |> Dict.toList |> List.map viewComponent)
                ]
        , if Dict.isEmpty resources then
            text ""

          else
            div []
                [ div [ class "ms-2 mb-1" ]
                    [ small [ class "text-body-secondary" ] [ text "Resources" ] ]
                , viewBulletList
                    (resources |> Dict.toList |> List.map viewResource)
                ]
        , div [ class "ms-2 mb-1" ]
            [ small [ class "text-body-secondary" ] [ text "Runtimes" ] ]
        , div [ class "ms-2 mb-3" ]
            (listAppRuntimeAvailable pageApp.pageApp_app
                |> List.map
                    (\r ->
                        viewRuntimeBadge r
                    )
            )
        ]


viewPageAppResources : Model -> PageApp -> Html Update
viewPageAppResources model pageApp =
    let
        routeApp =
            pageApp.pageApp_route
    in
    div
        [ class "box-container target-highlight mb-3"
        , id (showRouteAppFocus RouteAppFocus_Resources)
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
                        |> routeToString
                    )
                ]
                []
            ]
        , ul [ style "padding-left" "10px" ]
            (List.concat
                [ viewPageAppResourcesItem "Homepage" pageApp.pageApp_app.app_links.appLinks_website
                , viewPageAppResourcesItem "Documentation" pageApp.pageApp_app.app_links.appLinks_docs
                , viewPageAppResourcesItem "Source Repository" pageApp.pageApp_app.app_links.appLinks_source
                , viewPageAppResourcesItem "Forge Recipe" (Just (showAppRecipeLink model pageApp.pageApp_app))
                ]
            )
        ]


viewPageAppMaintainers : Model -> PageApp -> Html msg
viewPageAppMaintainers _ pageApp =
    let
        routeApp =
            pageApp.pageApp_route
    in
    if List.isEmpty pageApp.pageApp_app.app_maintainers then
        text ""

    else
        div
            [ class "box-container target-highlight mb-3"
            , id (showRouteAppFocus RouteAppFocus_Maintainers)
            , tabindex -1
            ]
            [ h6
                [ class "mt-3 mb-3 ms-2"
                ]
                [ text "Maintainers"
                , a
                    [ class "anchor-link"
                    , href
                        ({ routeApp | routeApp_focus = Just RouteAppFocus_Maintainers }
                            |> Route_App
                            |> routeToString
                        )
                    ]
                    []
                ]
            , ul [ style "padding-left" "10px" ]
                (List.map viewMaintainerItem pageApp.pageApp_app.app_maintainers)
            ]


maintainerGithubUrl : String -> String
maintainerGithubUrl handle =
    "https://github.com/" ++ handle


viewMaintainerItem : Maintainer -> Html msg
viewMaintainerItem m =
    li [ class "list-group-item bg-transparent px-0 mb-1" ]
        [ case m.maintainer_github of
            Just handle ->
                a
                    [ href (maintainerGithubUrl handle)
                    , target "_blank"
                    , rel "noopener"
                    ]
                    [ text m.maintainer_name ]

            Nothing ->
                text m.maintainer_name
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
        , app.app_recipePath
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
            , id (showRouteAppFocus RouteAppFocus_Grants)
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
                            |> routeToString
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
        div [ class "ms-2 mb-1" ]
            [ div [ class "mb-1" ]
                [ small [ class "text-body-secondary" ] [ text grant ] ]
            , ul
                [ class "mb-1 ms-3"
                , style "list-style-type" "none"
                , style "padding" "0px"
                ]
                (List.map
                    (\subgrant ->
                        li [ class "mb-1" ]
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


getAppScreenshotPath : AppName -> Int -> String
getAppScreenshotPath name index =
    "resources/apps/" ++ name ++ "/screenshots/" ++ String.fromInt index ++ ".webp"


getAppScreenshotThumbnailPath : AppName -> Int -> String
getAppScreenshotThumbnailPath name index =
    "resources/apps/" ++ name ++ "/screenshots/" ++ String.fromInt index ++ "-thumb.webp"


defaultAppIconPath : String
defaultAppIconPath =
    "resources/apps/app-icon.svg"


viewPageAppIconModal : Model -> PageApp -> Html Update
viewPageAppIconModal _ pageApp =
    let
        routeApp =
            pageApp.pageApp_route

        onClickRoute =
            Route_App { routeApp | routeApp_iconShown = False }
    in
    if not pageApp.pageApp_route.routeApp_iconShown then
        text ""

    else
        div []
            [ div
                [ class "modal show"
                , style "display" "block"
                , attribute "data-testid" "icon-modal-container"
                , tabindex -1
                , style "background-color" "rgba(0,0,0,0.5)"
                , onClick (Update_RouteWithoutHistory onClickRoute)
                ]
                [ div
                    [ class "modal-dialog modal-dialog-centered modal-lg"
                    , stopPropagationOn "click" (Decode.succeed ( Update_NoOp, True ))
                    ]
                    [ div
                        [ class "modal-content bg-transparent border-0"
                        , style "align-items" "center"
                        , style "justify-content" "center"
                        ]
                        [ div
                            [ style "position" "relative"
                            , style "display" "inline-block"
                            ]
                            [ button
                                [ class "btn-close btn-close-white opacity-100"
                                , attribute "type" "button"
                                , attribute "aria-label" "Close"
                                , onClick (Update_RouteWithoutHistory onClickRoute)
                                , style "position" "absolute"
                                , style "top" "-40px"
                                , style "right" "0"
                                ]
                                []
                            , (if pageApp.pageApp_app.app_hasIcon then
                                img

                               else
                                Html.node "avatar-icon"
                              )
                                ([ class "rounded bg-transparent"
                                 , style "width" "400px"
                                 , style "height" "400px"
                                 , style "object-fit" "contain"
                                 , style "max-width" "90vw"
                                 , style "max-height" "80vh"
                                 , attribute "alt" (pageApp.pageApp_app.app_displayName ++ " icon")
                                 , attribute "data-display-name" pageApp.pageApp_app.app_displayName
                                 , attribute "data-app-name" pageApp.pageApp_route.routeApp_name
                                 ]
                                    ++ (if pageApp.pageApp_app.app_hasIcon then
                                            [ src (getAppIconPath pageApp.pageApp_route.routeApp_name) ]

                                        else
                                            []
                                       )
                                )
                                []
                            ]
                        ]
                    ]
                ]
            ]
