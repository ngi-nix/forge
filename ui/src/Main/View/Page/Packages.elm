module Main.View.Page.Packages exposing (..)

import Html exposing (Html, a, code, div, h5, span, text)
import Html.Attributes exposing (attribute, class, href, id, rel, style, target, title)
import Main.Config exposing (..)
import Main.Config.Package exposing (..)
import Main.Helpers.AppUrl exposing (..)
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


viewPagePackagesLink : Html Update
viewPagePackagesLink =
    let
        onClickRoute =
            Route_Packages defaultRoutePackages
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


viewPagePackages : Model -> PagePackages -> Html Update
viewPagePackages model pagePackages =
    viewPagination
        PaginationVisibility_AlwaysVisible
        pagePackages.pagePackages_pagination
        (viewPagePackagesItem model pagePackages)
        (\modifyRoutePagination ->
            let
                routePackages =
                    pagePackages.pagePackages_route
            in
            Route_Packages
                { routePackages
                    | routePackages_pagination = routePackages.routePackages_pagination |> modifyRoutePagination
                    , routePackages_focus = Nothing
                }
        )


viewPagePackagesItem : Model -> PagePackages -> Package -> Html Update
viewPagePackagesItem model pagePackages package =
    let
        routePackages =
            pagePackages.pagePackages_route

        itemId =
            package.package_name

        onClickRoute =
            Route_Packages
                { routePackages
                    | routePackages_focus = Just <| RoutePackagesFocus_Package itemId
                }
    in
    a
        [ class "list-item list-group-item list-group-item-action flex-column align-items-start"
        , id itemId
        , href (onClickRoute |> routeToString)
        , attribute "data-testid" "package-result"
        , onClick (Update_Route onClickRoute)
        ]
        [ div
            []
            [ div [ class "d-flex w-100 justify-content-between" ]
                [ h5
                    [ class "mb-1"
                    ]
                    [ code []
                        [ text package.package_name
                        ]
                    , span
                        [ style "font-size" ".8rem"
                        , style "font-style" "italic"
                        , style "margin-left" "1em"
                        ]
                        [ text ("v" ++ package.package_version) ]
                    ]
                ]
            , package.package_description |> Markdown.render
            ]
        , div [ class "d-flex gap-3" ]
            [ a
                [ href package.package_license.license_url
                , target "_blank"
                , rel "noopener"
                , onClickStopPropagation
                ]
                [ text package.package_license.license_spdxId ]
            , a
                [ href <| showPackageRecipeLink model package
                , target "_blank"
                , rel "noopener"
                , onClickStopPropagation
                ]
                [ text "Forge Recipe" ]
            ]
        ]


showPackageRecipeLink : Model -> Package -> String
showPackageRecipeLink model package =
    String.join "/"
        [ model.model_config.config_repository |> showNixUrl
        , "blob/" ++ commit
        , package.package_recipePath
        ]
