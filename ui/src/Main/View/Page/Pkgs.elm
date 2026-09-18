module Main.View.Page.Pkgs exposing (..)

import Dict
import Html exposing (Html, a, code, div, h5, span, text)
import Html.Attributes exposing (attribute, class, href, id, rel, style, target, title)
import Main.Config exposing (..)
import Main.Config.Pkg exposing (..)
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
import Main.View.Pagination exposing (..)


viewPagePkgsLink : Html Update
viewPagePkgsLink =
    let
        onClickRoute =
            Route_Pkgs defaultRoutePkgs
    in
    a
        [ href (onClickRoute |> routeToString)
        , style "color" "inherit"
        , style "text-decoration" "none"
        , style "cursor" "pointer"
        , class "nav-link px-0 fw-bold"
        , title "View available packages"
        , attribute "aria-label" "View available packages"
        , onClick (Update_Route onClickRoute)
        ]
        [ text "Packages" ]


viewPagePkgs : Model -> PagePkgs -> Html Update
viewPagePkgs model pagePkgs =
    let
        reRoute =
            \modifyRoutePagination ->
                let
                    routePkgs =
                        pagePkgs.pagePkgs_route
                in
                Route_Pkgs
                    { routePkgs
                        | routePkgs_pagination = routePkgs.routePkgs_pagination |> modifyRoutePagination
                        , routePkgs_focus = Nothing
                    }
    in
    div []
        [ div
            [ class "d-flex flex-column flex-md-row align-items-center my-2 gap-3 w-100" ]
            [ div
                [ class "d-flex flex-wrap flex-md-nowrap justify-content-center justify-content-md-start align-items-center gap-2 flex-grow-1 w-100"
                , style "flex-basis" "0"
                ]
                [ viewPkgsCount model pagePkgs ]
            , div [ class "flex-shrink-0" ]
                [ viewPaginationNavigation PaginationVisibility_AlwaysVisible pagePkgs.pagePkgs_pagination reRoute ]
            , div
                [ class "d-none d-md-block flex-grow-1"
                , style "flex-basis" "0"
                ]
                []
            ]
        , viewPaginationContent pagePkgs.pagePkgs_pagination (viewPagePkgsItem model pagePkgs)
        , viewPaginationNavigation PaginationVisibility_AlwaysVisible pagePkgs.pagePkgs_pagination reRoute
        ]


viewPkgsCount : Model -> PagePkgs -> Html Update
viewPkgsCount model pagePkgs =
    viewCountWidget
        { total = Dict.size model.model_config.config_pkgs
        , filtered = pagePkgs.pagePkgs_pagination.pagePagination_list |> List.concat |> List.length
        , noun = "packages"
        , testId = "pkgs-count-badge"
        }


viewPagePkgsItem : Model -> PagePkgs -> Pkg -> Html Update
viewPagePkgsItem model pagePkgs pkg =
    let
        routePkgs =
            pagePkgs.pagePkgs_route

        itemId =
            pkg.pkg_pname

        onClickRoute =
            Route_Pkgs
                { routePkgs
                    | routePkgs_focus = Just <| RoutePkgsFocus_Pkg itemId
                }
    in
    div
        [ class "list-item list-group-item list-group-item-action flex-column align-items-start position-relative"
        , id itemId
        , attribute "data-testid" "pkg-result"
        , onClick (Update_Route onClickRoute)
        , style "cursor" "pointer"
        ]
        [ div
            []
            [ div [ class "d-flex w-100 justify-content-between" ]
                [ h5
                    [ class "mb-1"
                    ]
                    [ a
                        [ href (onClickRoute |> routeToString)
                        , class "text-decoration-none"
                        , onClick (Update_Route onClickRoute)
                        , style "color" "inherit"
                        , attribute "draggable" "false"
                        ]
                        [ code []
                            [ text pkg.pkg_pname
                            ]
                        ]
                    , span
                        [ style "font-size" ".8rem"
                        , style "font-style" "italic"
                        , style "margin-left" "1em"
                        ]
                        [ text ("v" ++ pkg.pkg_version) ]
                    ]
                ]
            , pkg.pkg_description |> Markdown.render
            ]
        , div [ class "d-flex flex-wrap gap-3 position-relative z-2" ]
            (List.append
                (pkg.pkg_licenses |> List.map viewLicense)
                [ a
                    [ href <| showPkgRecipeLink model pkg
                    , target "_blank"
                    , rel "noopener"
                    , onClickStopPropagation
                    ]
                    [ text "Forge Recipe" ]
                ]
            )
        ]


viewLicense : PkgLicense -> Html Update
viewLicense obj =
    let
        label =
            obj.license_spdxId
                |> Maybe.withDefault (obj.license_fullName |> Maybe.withDefault "Unknown License")
    in
    case obj.license_url of
        Just url ->
            a
                [ href url
                , target "_blank"
                , rel "noopener"
                , onClickStopPropagation
                ]
                [ text label ]

        Nothing ->
            span [] [ text label ]


showPkgRecipeLink : Model -> Pkg -> String
showPkgRecipeLink model pkg =
    String.join "/"
        [ model.model_config.config_repository |> showNixUrl
        , "blob/" ++ commit
        , pkg.pkg_recipePath
        ]
