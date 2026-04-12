module Main.View.Pagination exposing (..)

import Html exposing (Html, button, div, span, text)
import Html.Attributes exposing (attribute, class, disabled, style)
import Main.Config exposing (..)
import Main.Config.Package exposing (..)
import Main.Helpers.AppUrl exposing (..)
import Main.Helpers.Html exposing (..)
import Main.Helpers.List as List
import Main.Helpers.Nix exposing (..)
import Main.Icons exposing (..)
import Main.Model exposing (..)
import Main.Model.Page exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Model.Route exposing (..)
import Main.Update exposing (..)
import Main.Update.Types exposing (..)


type PaginationVisibility
    = PaginationVisibility_AlwaysVisible
    | PaginationVisibility_HiddenIfSinglePage


viewPagination : PaginationVisibility -> PagePagination a -> (a -> Html Update) -> ((RoutePagination -> RoutePagination) -> Route) -> Html Update
viewPagination visibility pagePagination viewItem reRoute =
    div []
        [ viewPaginationNavigation visibility reRoute pagePagination
        , viewPaginationContent pagePagination viewItem
        , viewPaginationNavigation visibility reRoute pagePagination
        ]


viewPaginationContent : PagePagination a -> (a -> Html Update) -> Html Update
viewPaginationContent pagePagination viewItem =
    div [ class "list-group" ]
        (viewPaginationItems pagePagination viewItem)


viewPaginationItems : PagePagination a -> (a -> Html Update) -> List (Html Update)
viewPaginationItems pagePagination viewItem =
    pagePagination.pagePagination_list
        |> List.at (pagePagination.pagePagination_current - 1)
        |> Maybe.withDefault []
        |> List.map viewItem


viewPaginationNavigation : PaginationVisibility -> ((RoutePagination -> RoutePagination) -> Route) -> PagePagination a -> Html Update
viewPaginationNavigation visibility reRoute pagePagination =
    let
        isHidden =
            case visibility of
                PaginationVisibility_AlwaysVisible ->
                    False

                PaginationVisibility_HiddenIfSinglePage ->
                    pagePagination.pagePagination_last <= 1
    in
    if isHidden then
        text ""

    else
        let
            updatePageNumber pagination =
                reRoute <|
                    \routePagination ->
                        { routePagination
                            | routePagination_current = Just pagination.pagePagination_current
                        }

            routePagePreviousMaybe : Maybe Route
            routePagePreviousMaybe =
                pagePagination
                    |> previousPagePagination
                    |> Maybe.map updatePageNumber

            routePageNextMaybe : Maybe Route
            routePageNextMaybe =
                pagePagination
                    |> nextPagePagination
                    |> Maybe.map updatePageNumber
        in
        div [ class "d-flex justify-content-center align-items-center my-2" ]
            [ button
                ([ class "btn me-2 border-0"
                 , attribute "data-testid" "pagination-prev"
                 ]
                    ++ (case routePagePreviousMaybe of
                            Nothing ->
                                [ disabled True ]

                            Just routePagePrevious ->
                                [ onClick (Update_Route routePagePrevious), class "focus-ring" ]
                       )
                )
                [ text "Prev" ]
            , span
                [ style "width" "2rem"
                , style "text-align" "center"
                , attribute "data-testid" "pagination-current"
                ]
                [ text (pagePagination.pagePagination_current |> String.fromInt) ]
            , text " / "
            , span
                [ style "width" "2rem"
                , style "text-align" "center"
                ]
                [ text (pagePagination.pagePagination_last |> String.fromInt) ]
            , button
                ([ class "btn me-2 border-0"
                 , attribute "data-testid" "pagination-next"
                 ]
                    ++ (case routePageNextMaybe of
                            Nothing ->
                                [ disabled True ]

                            Just routePageNext ->
                                [ onClick (Update_Route routePageNext), class "focus-ring" ]
                       )
                )
                [ text "Next" ]
            ]
