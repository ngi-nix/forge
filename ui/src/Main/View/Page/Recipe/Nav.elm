module Main.View.Page.Recipe.Nav exposing (viewPageRecipeOptionsNav)

import Html exposing (Html, a, div, nav, span, text)
import Html.Attributes exposing (class, href, style)
import List.Extra as List
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Helpers.Html exposing (..)
import Main.Helpers.List as List
import Main.Helpers.Nix exposing (..)
import Main.Helpers.Tree as Tree
import Main.Icons exposing (..)
import Main.Model exposing (..)
import Main.Model.Page exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Model.Route exposing (..)
import Main.Update exposing (..)
import Main.Update.Types exposing (..)
import Main.View.Page.App exposing (..)
import Main.View.Pagination exposing (..)
import Set
import Tree exposing (Tree)
import Tuple exposing (first)


viewPageRecipeOptionsNav : Model -> PageRecipeOptions -> Html Update
viewPageRecipeOptionsNav _ page =
    let
        initInh =
            { inhRecipeOptionsNav_pathReversed = []
            , inhRecipeOptionsNav_unfolded = True
            , inhRecipeOptionsNav_children = []
            }
    in
    page.pageRecipeOptions_trees
        |> List.map (viewPageRecipeOptionsNavNodes page initInh)
        |> (\hs ->
                let
                    h =
                        viewPageRecipeOptionsNavNode page
                            { inhRecipeOptionsNav_pathReversed = []
                            , inhRecipeOptionsNav_children = page.pageRecipeOptions_trees
                            , inhRecipeOptionsNav_unfolded = True
                            }
                            (Tree.tree ( "", [] ) page.pageRecipeOptions_trees)
                            { nodeRecipeOptionsNav_foldable = True
                            , nodeRecipeOptionsNav_unfolded = True
                            , nodeRecipeOptionsNav_showable = True
                            , nodeRecipeOptionsNav_shown = True
                            }
                in
                nav [ class "option-dirs" ]
                    [ div
                        [ style "margin-left" "1rem"
                        ]
                        (h
                            :: hs
                        )
                    ]
           )


viewPageRecipeOptionsNavNodes : PageRecipeOptions -> InhRecipeOptionsNav -> Tree NodeNixOption -> Html Update
viewPageRecipeOptionsNavNodes page inh tree =
    let
        unfoldedAncestorsOrSelf =
            page.pageRecipeOptions_unfolds
                |> Set.toList
                |> List.concatMap List.inits
                |> Set.fromList

        name =
            tree |> Tree.label |> first

        childrenInh =
            { inh
                | inhRecipeOptionsNav_pathReversed =
                    (if name == "" then
                        []

                     else
                        [ name ]
                    )
                        ++ inh.inhRecipeOptionsNav_pathReversed
                , inhRecipeOptionsNav_unfolded = unfolded
                , inhRecipeOptionsNav_children = tree |> Tree.children
            }

        synHtml =
            tree |> Tree.children |> List.map (viewPageRecipeOptionsNavNodes page childrenInh)

        path =
            pathPageRecipeOptionsNav inh tree

        nodeBranches =
            synHtml |> List.length

        showable =
            0 < nodeBranches

        shown =
            showable
                && (unfolded
                        || inh.inhRecipeOptionsNav_unfolded
                   )

        unfolded =
            Set.member path unfoldedAncestorsOrSelf
                || (inh.inhRecipeOptionsNav_unfolded && List.length inh.inhRecipeOptionsNav_children == 1)

        foldable =
            tree
                |> Tree.children
                |> List.filter (Tree.children >> List.length >> (<) 0)
                |> List.length
                |> (<) 0

        node =
            { nodeRecipeOptionsNav_showable = showable
            , nodeRecipeOptionsNav_foldable = foldable
            , nodeRecipeOptionsNav_unfolded = unfolded
            , nodeRecipeOptionsNav_shown = shown
            }
    in
    div
        [ style "margin-left" "1rem"
        ]
    <|
        List.concat
            [ if shown then
                [ viewPageRecipeOptionsNavNode page inh tree node
                ]

              else
                []
            , synHtml
            ]


viewPageRecipeOptionsNavNode : PageRecipeOptions -> InhRecipeOptionsNav -> Tree NodeNixOption -> NodeRecipeOptionsNav -> Html Update
viewPageRecipeOptionsNavNode page inh tree node =
    div
        [ style "font-family" "monospace"
        ]
    <|
        [ span [ style "white-space" "pre" ] <|
            [ viewPageRecipeOptionsNavNodeName page inh tree node
            ]
        ]


viewPageRecipeOptionsNavNodeName : PageRecipeOptions -> InhRecipeOptionsNav -> Tree NodeNixOption -> NodeRecipeOptionsNav -> Html Update
viewPageRecipeOptionsNavNodeName page inh tree node =
    let
        name =
            tree |> Tree.label |> first

        path =
            pathPageRecipeOptionsNav inh tree
    in
    span []
        [ viewPageRecipeOptionsNavNodeToggle page inh tree node
        , a
            [ href (routePageRecipeOptionsNavNodeName page path |> routeToString)
            , onClick (Update_Route (routePageRecipeOptionsNavNodeName page path))
            , class "text-primary"
            , style "text-decoration" <|
                if path == page.pageRecipeOptions_route.routeRecipeOptions_scope then
                    "underline"

                else
                    "none"
            ]
            [ text <|
                if name == "" then
                    "<recipe>"

                else
                    name
            ]
        ]


routePageRecipeOptionsNavNodeName : PageRecipeOptions -> NixPath -> Route
routePageRecipeOptionsNavNodeName page path =
    let
        route =
            page.pageRecipeOptions_route
    in
    Route_RecipeOptions
        { route
            | routeRecipeOptions_scope = path
            , routeRecipeOptions_unfolds =
                route.routeRecipeOptions_unfolds
                    |> Set.insert path
            , routeRecipeOptions_focus = Nothing
        }


viewPageRecipeOptionsNavNodeToggle : PageRecipeOptions -> InhRecipeOptionsNav -> Tree NodeNixOption -> NodeRecipeOptionsNav -> Html Update
viewPageRecipeOptionsNavNodeToggle page inh tree node =
    let
        path =
            pathPageRecipeOptionsNav inh tree
    in
    span
        [ style "white-space" "pre"
        ]
        [ if node.nodeRecipeOptionsNav_foldable then
            a
                [ href (routePageRecipeOptionsNavNodeToggle page path |> routeToString)
                , onClick (Update_Route (routePageRecipeOptionsNavNodeToggle page path))
                , style "color" "inherit"
                , class "fw-bold"
                , class "text-secondary"
                ]
                [ text <|
                    if node.nodeRecipeOptionsNav_unfolded then
                        "⌄ "

                    else
                        "› "
                ]

          else
            text "  "
        ]


routePageRecipeOptionsNavNodeToggle : PageRecipeOptions -> NixPath -> Route
routePageRecipeOptionsNavNodeToggle page path =
    let
        route =
            page.pageRecipeOptions_route
    in
    Route_RecipeOptions <|
        if route.routeRecipeOptions_unfolds |> Set.member path then
            { route
                | routeRecipeOptions_unfolds =
                    route.routeRecipeOptions_unfolds
                        |> Set.filter (List.isPrefixOf path >> not)
                        |> Set.insert (path |> List.dropLast |> Maybe.withDefault [])
                , routeRecipeOptions_scope =
                    if route.routeRecipeOptions_scope == path then
                        []

                    else
                        route.routeRecipeOptions_scope
                , routeRecipeOptions_focus = Nothing
            }

        else
            { route
                | routeRecipeOptions_unfolds =
                    route.routeRecipeOptions_unfolds
                        |> Set.insert path
                , routeRecipeOptions_focus = Nothing
            }


type alias InhRecipeOptionsNav =
    { inhRecipeOptionsNav_pathReversed : NixPath
    , inhRecipeOptionsNav_unfolded : Bool
    , inhRecipeOptionsNav_children : List (Tree NodeNixOption)
    }


pathPageRecipeOptionsNav : InhRecipeOptionsNav -> Tree NodeNixOption -> NixPath
pathPageRecipeOptionsNav inh tree =
    let
        name =
            tree |> Tree.label |> first
    in
    (name :: inh.inhRecipeOptionsNav_pathReversed) |> List.reverse


type alias NodeRecipeOptionsNav =
    { nodeRecipeOptionsNav_foldable : Bool
    , nodeRecipeOptionsNav_unfolded : Bool
    , nodeRecipeOptionsNav_showable : Bool
    , nodeRecipeOptionsNav_shown : Bool
    }
