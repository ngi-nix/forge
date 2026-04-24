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


viewPageRecipeOptionsBrowser : Model -> PageRecipeOptions -> Html Update
viewPageRecipeOptionsBrowser _ page =
    let
        initInh =
            { inh_parentPath = []
            , inh_parentUnfolded = True
            , inh_parentChildren = []
            }
    in
    page.pageRecipeOptions_trees
        |> List.map (viewNodes page initInh)
        |> nav
            [ style "border" "1px solid var(--bs-border-color)"
            , style "border-radius" "6px"
            , style "padding" "1em .5em 1em 0"
            ]


viewNodes : PageRecipeOptions -> Inh -> Tree NodeNixOption -> Html Update
viewNodes page inh tree =
    let
        ( name, _ ) =
            tree |> Tree.label

        path =
            inh.inh_parentPath ++ [ name ]

        childrenInh =
            { inh
                | inh_parentPath =
                    inh.inh_parentPath
                        ++ (if name == "" then
                                []

                            else
                                [ name ]
                           )
                , inh_parentUnfolded = unfolded
                , inh_parentChildren = tree |> Tree.children
            }

        ( nodeChildrenLeaves, nodeChildrenBranches ) =
            tree |> Tree.children |> List.partition (Tree.children >> List.isEmpty)

        childrenHtml =
            [ nodeChildrenLeaves, nodeChildrenBranches ]
                |> List.concatMap (List.map (viewNodes page childrenInh))

        shown =
            unfolded || inh.inh_parentUnfolded

        unfolded =
            Set.member path page.pageRecipeOptions_unfolds
                || autoUnfolded

        autoUnfolded =
            inh.inh_parentUnfolded && List.length inh.inh_parentChildren == 1

        foldable =
            tree
                |> Tree.children
                |> List.length
                |> (<) 0

        node =
            { node_foldable = foldable
            , node_unfolded = unfolded
            , node_autoUnfolded = autoUnfolded
            }
    in
    div
        (if node.node_foldable then
            [ style "margin-left" "1rem" ]

         else
            [ style "margin-left" "calc(2rem + 3px)" ]
        )
    <|
        List.concat
            [ if shown then
                viewNode page inh tree node
                    :: childrenHtml

              else
                []
            ]


viewNode :
    PageRecipeOptions
    -> Inh
    -> Tree NodeNixOption
    -> Node
    -> Html Update
viewNode page inh tree node =
    div
        [ style "font-family" "monospace"
        ]
        [ span [ style "white-space" "pre" ] <|
            [ viewNodeToggle page inh tree node
            , viewNodeName page inh tree
            ]
        ]


viewNodeToggle :
    PageRecipeOptions
    -> Inh
    -> Tree NodeNixOption
    -> Node
    -> Html Update
viewNodeToggle page inh tree node =
    let
        ( name, _ ) =
            tree |> Tree.label

        path =
            inh.inh_parentPath ++ [ name ]
    in
    if node.node_foldable then
        span
            [ style "white-space" "pre"
            ]
            [ (if node.node_autoUnfolded then
                span

               else
                a
                    << (++)
                        [ href (routeNodeToggle page path |> routeToString)
                        , onClick (Update_Route (routeNodeToggle page path))
                        ]
              )
                [ style "color" "inherit"
                , class "fw-bold"
                , class "text-secondary"
                ]
                [ text <|
                    if node.node_unfolded then
                        "⌄ "

                    else
                        "› "
                ]
            ]

    else
        text ""


viewNodeName :
    PageRecipeOptions
    -> Inh
    -> Tree NodeNixOption
    -> Html Update
viewNodeName page inh tree =
    let
        ( name, _ ) =
            tree |> Tree.label

        path =
            inh.inh_parentPath ++ [ name ]
    in
    a
        (List.concat
            [ [ href (routeNodeName page tree path |> routeToString)
              , onClick (Update_Route (routeNodeName page tree path))
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


routeNodeName : PageRecipeOptions -> Tree NodeNixOption -> NixAttrPath -> Route
routeNodeName page tree path =
    let
        route =
            page.pageRecipeOptions_route
    in
    Route_RecipeOptions <|
        if path == route.routeRecipeOptions_scope then
            -- Unscope and fold the node at `path`.
            { route
                | routeRecipeOptions_scope = []
                , routeRecipeOptions_unfolds =
                    -- Remove any unfold descendant-or-self of the folded node.
                    route.routeRecipeOptions_unfolds
                        |> Set.filter (List.isPrefixOf path >> not)
                        |> Set.insert (path |> List.dropLast |> Maybe.withDefault [])
                , routeRecipeOptions_focus = Nothing
            }

        else
            -- Scope the node at `path`.
            { route
                | routeRecipeOptions_scope = path
                , routeRecipeOptions_unfolds =
                    -- Unfold the scoped node, only when it has any.
                    route.routeRecipeOptions_unfolds
                        |> (if tree |> Tree.children |> List.isEmpty then
                                identity

                            else
                                Set.insert path
                           )
                , routeRecipeOptions_focus = Nothing
            }


routeNodeToggle : PageRecipeOptions -> NixAttrPath -> Route
routeNodeToggle page path =
    let
        route =
            page.pageRecipeOptions_route
    in
    Route_RecipeOptions <|
        if page.pageRecipeOptions_unfolds |> Set.member path then
            -- Fold the node at `path`.
            { route
                | routeRecipeOptions_unfolds =
                    -- Remove any unfold descendant-or-self of the folded node.
                    page.pageRecipeOptions_route.routeRecipeOptions_unfolds
                        |> Set.filter (List.isPrefixOf path >> not)
                        |> Set.insert (path |> List.dropLast |> Maybe.withDefault [])
                , routeRecipeOptions_scope =
                    -- Remove any scope descendant-or-self of the folded node.
                    if route.routeRecipeOptions_scope |> List.isPrefixOf path then
                        []

                    else
                        route.routeRecipeOptions_scope
                , routeRecipeOptions_focus = Nothing
            }

        else
            -- Unfold the node at `path`.
            { route
                | routeRecipeOptions_unfolds =
                    page.pageRecipeOptions_route.routeRecipeOptions_unfolds
                        |> Set.insert path
                , routeRecipeOptions_focus = Nothing
            }


type alias Inh =
    { inh_parentPath : NixAttrPath
    , inh_parentUnfolded : Bool
    , inh_parentChildren : List (Tree NodeNixOption)
    }


type alias Node =
    { node_foldable : Bool
    , node_unfolded : Bool
    , node_autoUnfolded : Bool
    }
