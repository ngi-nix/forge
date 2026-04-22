module Main.View.Page.Recipe.Browser exposing (viewPageRecipeOptionsBrowser)

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


viewPageRecipeOptionsBrowser : Model -> PageRecipeOptions -> Html Update
viewPageRecipeOptionsBrowser _ page =
    let
        initInh =
            { inhRecipeOptionsBrowser_pathReversed = []
            , inhRecipeOptionsBrowser_unfolded = True
            , inhRecipeOptionsBrowser_children = []
            }
    in
    page.pageRecipeOptions_trees
        |> List.map (viewPageRecipeOptionsBrowserNodes page initInh)
        |> nav
            [ style "border" "1px solid var(--bs-border-color)"
            , style "border-radius" "6px"
            , style "padding" "1em .5em 1em 0"
            ]


viewPageRecipeOptionsBrowserNodes : PageRecipeOptions -> InhRecipeOptionsBrowser -> Tree NodeNixOption -> Html Update
viewPageRecipeOptionsBrowserNodes page inh tree =
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
                | inhRecipeOptionsBrowser_pathReversed =
                    (if name == "" then
                        []

                     else
                        [ name ]
                    )
                        ++ inh.inhRecipeOptionsBrowser_pathReversed
                , inhRecipeOptionsBrowser_unfolded = unfolded
                , inhRecipeOptionsBrowser_children = tree |> Tree.children
            }

        ( nodeChildrenLeaves, nodeChildrenBranches ) =
            tree |> Tree.children |> List.partition (Tree.children >> List.isEmpty)

        childrenHtml =
            [ nodeChildrenLeaves, nodeChildrenBranches ]
                |> List.concatMap (List.map (viewPageRecipeOptionsBrowserNodes page childrenInh))

        path =
            pathPageRecipeOptionsBrowser inh tree

        shown =
            unfolded || inh.inhRecipeOptionsBrowser_unfolded

        unfolded =
            Set.member path unfoldedAncestorsOrSelf
                || (inh.inhRecipeOptionsBrowser_unfolded && List.length inh.inhRecipeOptionsBrowser_children == 1)

        foldable =
            tree
                |> Tree.children
                |> List.length
                |> (<) 0

        node =
            { nodeRecipeOptionsBrowser_foldable = foldable
            , nodeRecipeOptionsBrowser_unfolded = unfolded
            , nodeRecipeOptionsBrowser_shown = shown
            }
    in
    div
        (if node.nodeRecipeOptionsBrowser_foldable then
            [ style "margin-left" "1rem" ]

         else
            [ style "margin-left" "calc(2rem + 3px)" ]
        )
    <|
        List.concat
            [ if shown then
                [ viewPageRecipeOptionsBrowserNode page inh tree node
                ]

              else
                []
            , childrenHtml
            ]


viewPageRecipeOptionsBrowserNode : PageRecipeOptions -> InhRecipeOptionsBrowser -> Tree NodeNixOption -> NodeRecipeOptionsBrowser -> Html Update
viewPageRecipeOptionsBrowserNode page inh tree node =
    div
        [ style "font-family" "monospace"
        ]
        [ viewPageRecipeOptionsBrowserNodeToggle page inh tree node
        , viewPageRecipeOptionsBrowserNodeName page inh tree node
        ]


viewPageRecipeOptionsBrowserNodeToggle : PageRecipeOptions -> InhRecipeOptionsBrowser -> Tree NodeNixOption -> NodeRecipeOptionsBrowser -> Html Update
viewPageRecipeOptionsBrowserNodeToggle page inh tree node =
    let
        path =
            pathPageRecipeOptionsBrowser inh tree
    in
    if node.nodeRecipeOptionsBrowser_foldable then
        span
            [ style "white-space" "pre"
            ]
            [ a
                [ href (routePageRecipeOptionsBrowserNodeToggle page path |> routeToString)
                , onClick (Update_Route (routePageRecipeOptionsBrowserNodeToggle page path))
                , style "color" "inherit"
                , class "fw-bold"
                , class "text-secondary"
                ]
                [ text <|
                    if node.nodeRecipeOptionsBrowser_unfolded then
                        "⌄ "

                    else
                        "› "
                ]
            ]

    else
        text ""


viewPageRecipeOptionsBrowserNodeName : PageRecipeOptions -> InhRecipeOptionsBrowser -> Tree NodeNixOption -> NodeRecipeOptionsBrowser -> Html Update
viewPageRecipeOptionsBrowserNodeName page inh tree node =
    let
        name =
            tree |> Tree.label |> first

        path =
            pathPageRecipeOptionsBrowser inh tree
    in
    span []
        [ a
            (List.concat
                [ [ href (routePageRecipeOptionsBrowserNodeName page path |> routeToString)
                  , onClick (Update_Route (routePageRecipeOptionsBrowserNodeName page path))
                  ]
                , if path == page.pageRecipeOptions_route.routeRecipeOptions_scope then
                    [ style "font-weight" "bolder"
                    , class <|
                        if tree |> Tree.children |> (/=) [] then
                            "text-primary-emphasis"

                        else
                            "text-secondary-emphasis"
                    ]

                  else
                    [ class <|
                        if tree |> Tree.children |> (/=) [] then
                            "text-primary"

                        else
                            "text-secondary"
                    ]
                ]
            )
            [ text name
            ]
        ]


routePageRecipeOptionsBrowserNodeName : PageRecipeOptions -> NixAttrPath -> Route
routePageRecipeOptionsBrowserNodeName page path =
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


routePageRecipeOptionsBrowserNodeToggle : PageRecipeOptions -> NixAttrPath -> Route
routePageRecipeOptionsBrowserNodeToggle page path =
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
                    if List.isPrefixOf path route.routeRecipeOptions_scope then
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


type alias InhRecipeOptionsBrowser =
    { inhRecipeOptionsBrowser_pathReversed : NixAttrPath
    , inhRecipeOptionsBrowser_unfolded : Bool
    , inhRecipeOptionsBrowser_children : List (Tree NodeNixOption)
    }


pathPageRecipeOptionsBrowser : InhRecipeOptionsBrowser -> Tree NodeNixOption -> NixAttrPath
pathPageRecipeOptionsBrowser inh tree =
    let
        name =
            tree |> Tree.label |> first
    in
    (name :: inh.inhRecipeOptionsBrowser_pathReversed) |> List.reverse


type alias NodeRecipeOptionsBrowser =
    { nodeRecipeOptionsBrowser_foldable : Bool
    , nodeRecipeOptionsBrowser_unfolded : Bool
    , nodeRecipeOptionsBrowser_shown : Bool
    }
