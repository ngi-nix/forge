module Main.View.Pagination exposing (..)

import Html exposing (Html, button, div, span, text)
import Html.Attributes exposing (class, disabled, style)
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
import Main.Route exposing (..)
import Main.Update exposing (..)


viewPagination : PagePagination a -> (a -> Html Update) -> ((RoutePagination -> RoutePagination) -> Route) -> Html Update
viewPagination pagePagination viewItem reRoute =
    div []
        [ viewPaginationNavigation reRoute pagePagination
        , viewPaginationContent pagePagination viewItem
        , viewPaginationNavigation reRoute pagePagination
        ]


viewPaginationContent : PagePagination a -> (a -> Html Update) -> Html Update
viewPaginationContent pagePagination viewItem =
    div [ class "list-group" ]
        (pagePagination.pagePagination_list
            |> List.at (pagePagination.pagePagination_current - 1)
            |> Maybe.withDefault []
            |> List.map viewItem
        )


viewPaginationNavigation : ((RoutePagination -> RoutePagination) -> Route) -> PagePagination a -> Html Update
viewPaginationNavigation reRoute pagePagination =
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
            (class "btn me-2 border-0"
                :: (case routePagePreviousMaybe of
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
            ]
            [ text (pagePagination.pagePagination_current |> String.fromInt) ]
        , text " / "
        , span
            [ style "width" "2rem"
            , style "text-align" "center"
            ]
            [ text (pagePagination.pagePagination_last |> String.fromInt) ]
        , button
            (class "btn ms-2 border-0"
                :: (case routePageNextMaybe of
                        Nothing ->
                            [ disabled True ]

                        Just routePageNext ->
                            [ onClick (Update_Route routePageNext), class "focus-ring" ]
                   )
            )
            [ text "Next" ]
        ]
