module Main.View.Page.Pkgs exposing (..)

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
    viewPagination
        PaginationVisibility_AlwaysVisible
        pagePkgs.pagePkgs_pagination
        (viewPagePkgsItem model pagePkgs)
        (\modifyRoutePagination ->
            let
                routePkgs =
                    pagePkgs.pagePkgs_route
            in
            Route_Pkgs
                { routePkgs
                    | routePkgs_pagination = routePkgs.routePkgs_pagination |> modifyRoutePagination
                    , routePkgs_focus = Nothing
                }
        )


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
    a
        [ class "list-item list-group-item list-group-item-action flex-column align-items-start"
        , id itemId
        , href (onClickRoute |> routeToString)
        , attribute "data-testid" "pkg-result"
        , onClick (Update_Route onClickRoute)
        ]
        [ div
            []
            [ div [ class "d-flex w-100 justify-content-between" ]
                [ h5
                    [ class "mb-1"
                    ]
                    [ code []
                        [ text pkg.pkg_pname
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
        , div [ class "d-flex gap-3" ]
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
