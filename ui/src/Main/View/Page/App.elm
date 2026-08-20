module Main.View.Page.App exposing (..)

import Dict
import Html exposing (Html, a, button, div, h2, h4, h6, hr, img, li, p, small, span, text, ul)
import Html.Attributes exposing (attribute, class, href, id, rel, src, style, tabindex, target)
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
                , viewPageAppIconModal model pageApp
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
        , button
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


viewPageAppFeedback : Model -> Html Update
viewPageAppFeedback model =
    if model.model_preferences.preferences_feedbackDismissed then
        text ""

    else
        div [ class "alert alert-info alert-dismissible mt-3", attribute "data-testid" "feedback-message" ]
            [ text "Tried this app? We'd love to "
            , a
                [ href "https://cryptpad.ngi.nixos.org/form/#/2/form/view/3X1lzb3+XxsLUq-TygwGn-R3aHcvwuNo3L7Ya8Z1VWo/"
                , target "_blank"
                , rel "noopener"
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


viewPageAppDescription : Model -> PageApp -> Html Update
viewPageAppDescription model pageApp =
    div []
        [ p
            [ class "text-body-secondary"
            , attribute "data-testid" "app-description"
            ]
            [ text pageApp.pageApp_app.app_description ]
        , viewPageAppUsage model pageApp
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
    div []
        [ small [ class "text-body-secondary" ] [ text rname ]
        , viewPortList resource.appResource_ports
        ]


viewComponent : ( String, AppComponent ) -> Html Update
viewComponent ( cname, component ) =
    li []
        [ small [] [ text cname ]
        , viewPortList component.appComponent_ports
        , if Dict.isEmpty component.appComponent_resources then
            text ""

          else
            div [ class "ms-2" ]
                (component.appComponent_resources
                    |> Dict.toList
                    |> List.map viewResource
                )
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
        , div [ class "ms-2 mb-1" ]
            [ small [ class "text-body-secondary" ] [ text "Runtimes" ] ]
        , div [ class "ms-2 mb-3" ]
            (listAppRuntimeAvailable pageApp.pageApp_app
                |> List.map
                    (\r ->
                        span [ class "badge rounded-pill bg-primary-subtle text-primary-emphasis border border-primary-subtle me-1" ]
                            [ text (showAppRuntime r |> String.toLower) ]
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
