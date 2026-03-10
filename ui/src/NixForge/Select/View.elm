module NixForge.Select.View exposing (..)

import Html exposing (Html, button, div, hr, input, text)
import Html.Attributes exposing (class, placeholder, value)
import Html.Events exposing (onClick, onInput)
import NixForge.Config exposing (..)
import NixForge.Config.App exposing (..)
import NixForge.Config.Package exposing (..)
import NixForge.Output exposing (..)
import NixForge.Route exposing (..)
import NixForge.Select.Model exposing (..)
import NixForge.Select.Update exposing (..)
import NixForge.Select.View.Applications exposing (..)
import NixForge.Select.View.Instructions exposing (..)
import NixForge.Select.View.Packages exposing (..)


viewSelect : ModelSelect -> Html UpdateSelect
viewSelect model =
    div [ class "container" ]
        -- header
        [ div [ class "row" ]
            [ div
                [ class "col-lg-12 border fw-bold fs-1 py-2 my-2"
                ]
                -- header
                [ headerHtml ]
            ]

        -- content
        , div [ class "row" ]
            -- packages panel
            [ div [ class "col-lg-6 border bg-light py-3 my-3" ]
                [ div
                    [ class "name d-flex gap-2 justify-content-between align-items-center"
                    ]
                    [ div [ class "flex-grow-1" ]
                        (viewSearch model.searchString)
                    ]
                , div [ class "d-flex btn-group align-items-center" ]
                    (viewOuputs [ OutputCategory_Packages, OutputCategory_Applications ] model.selectedOutput)

                -- separator
                , div [] [ hr [] [] ]
                , div [ class "list-group" ]
                    (case model.selectedOutput of
                        OutputCategory_Packages ->
                            viewPackages model.packages model.selectedPackage model.searchString

                        OutputCategory_Applications ->
                            viewApps model.apps model.selectedApp model.searchString
                    )

                -- error message
                , case model.error of
                    Just errUpdate ->
                        div [] [ text ("Error: " ++ errUpdate) ]

                    Nothing ->
                        text ""
                ]

            -- instructions panel
            , div [ class "col-lg-6 bg-dark text-white py-3 my-3" ]
                [ case ( model.selectedPackage, model.selectedApp ) of
                    ( Nothing, Nothing ) ->
                        -- install instructions
                        div []
                            (installInstructionsHtml UpdateSelect_CopyCode)

                    _ ->
                        div []
                            (case model.selectedOutput of
                                OutputCategory_Packages ->
                                    packageInstructionsHtml model.repositoryUrl model.recipeDirPackages UpdateSelect_CopyCode model.selectedPackage

                                OutputCategory_Applications ->
                                    appInstructionsHtml model.repositoryUrl model.recipeDirApps UpdateSelect_CopyCode model.selectedApp
                            )
                ]
            ]

        -- footer
        , div [ class "col-sm-12" ]
            [ hr [] []

            -- footer
            , footerHtml
            ]
        ]


viewSearch : String -> List (Html UpdateSelect)
viewSearch searchString =
    [ input
        [ class "form-control form-control-lg py-2 my-2"
        , placeholder "Search for package or application ..."
        , value searchString
        , onInput UpdateSelect_Search
        ]
        []
    ]


viewOuputs : List OutputCategory -> OutputCategory -> List (Html UpdateSelect)
viewOuputs buttons activeButton =
    buttons
        |> List.map
            (\item ->
                button
                    [ class
                        ("btn btn-lg "
                            ++ (if item == activeButton then
                                    "btn-dark"

                                else
                                    "btn-secondary"
                               )
                        )
                    , onClick (UpdateSelect_Output item)
                    ]
                    [ text
                        (case item of
                            OutputCategory_Applications ->
                                "APPLICATIONS"

                            OutputCategory_Packages ->
                                "PACKAGES"
                        )
                    ]
            )
