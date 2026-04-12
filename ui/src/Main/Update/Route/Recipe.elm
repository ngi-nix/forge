module Main.Update.Route.Recipe exposing (..)

import Dict
import Http
import List.Extra as List
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Helpers.Nix exposing (..)
import Main.Helpers.Tree as Tree exposing (Trees)
import Main.Model exposing (..)
import Main.Model.Error exposing (..)
import Main.Model.Page exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Model.Route exposing (..)
import Main.Ports.SmoothScroll exposing (..)
import Main.Update.Focus exposing (..)
import Main.Update.Types exposing (..)
import String
import Tree exposing (Tree)
import Tuple exposing (first)


updateRouteRecipeOptions : RouteRecipeOptions -> Updater
updateRouteRecipeOptions route =
    getRecipeOptions <|
        \model ->
            let
                availableItems =
                    model.model_RecipeOptions.recipeOptions_available
                        |> Dict.toList
            in
            { model
                | model_page =
                    let
                        trees =
                            availableItems
                                |> nixOptionsTrees
                    in
                    Page_RecipeOptions
                        { pageRecipeOptions_route = route
                        , pageRecipeOptions_pagination =
                            trees
                                |> scopeRecipeOptions route.routeRecipeOptions_scope
                                |> filterRecipeOptions route []
                                |> List.concatMap (listRecipeOptionsItems { inhRouteRecipeOptionsItem_pathReversed = [] })
                                |> paginateRecipeOptions model route
                        , pageRecipeOptions_unfolds = route.routeRecipeOptions_unfolds
                        , pageRecipeOptions_trees = trees
                        }
                , model_search = route.routeRecipeOptions_searchPattern
            }
                |> updateFocus
                    showRouteRecipeOptionsFocus
                    (case model.model_page of
                        Page_RecipeOptions oldPageRecipe ->
                            oldPageRecipe.pageRecipeOptions_route.routeRecipeOptions_focus

                        _ ->
                            Nothing
                    )
                    route.routeRecipeOptions_focus


{-| `getRecipeOptions up` populates `model.model_recipe.modelRecipeOptions_available` if empty, then runs `up`.
`up` is thus always run, and only after `model.model_recipe.modelRecipeOptions_available` has been loaded.
-}
getRecipeOptions : Updater -> Updater
getRecipeOptions up model =
    if Dict.isEmpty model.model_RecipeOptions.recipeOptions_available then
        ( model
        , Http.get
            { url = "forge-options.json"
            , expect =
                Http.expectJson
                    (\res ->
                        Update_Chain
                            [ Update_RecipeOptions res
                            , Update_Updater up
                            ]
                    )
                    decodeNixModuleOptions
            }
        )

    else
        model |> up


scopeRecipeOptions : NixPath -> Trees NodeNixOption -> Trees NodeNixOptionFiltered
scopeRecipeOptions path trees =
    case path of
        [] ->
            trees |> List.map (Tree.map NodeNixOptionFiltered_In)

        p :: ps ->
            trees
                |> List.concatMap
                    (\tree ->
                        if tree |> Tree.label |> first |> (==) p then
                            [ Tree.tree
                                (NodeNixOptionFiltered_Out (tree |> Tree.label |> first))
                                (tree |> Tree.children |> scopeRecipeOptions ps)
                            ]

                        else
                            []
                    )


filterRecipeOptions : RouteRecipeOptions -> NixPath -> Trees NodeNixOptionFiltered -> Trees NodeNixOptionFiltered
filterRecipeOptions route path trees =
    trees
        |> List.map
            (\tree ->
                case tree |> Tree.label of
                    NodeNixOptionFiltered_Out n ->
                        Tree.tree
                            (NodeNixOptionFiltered_Out n)
                            (tree |> Tree.children |> filterRecipeOptions route (path ++ [ n ]))

                    NodeNixOptionFiltered_In ( n, vs ) ->
                        let
                            optionPath =
                                path ++ [ n ]
                        in
                        Tree.tree
                            (if vs |> List.any (filterRecipeOption route optionPath) then
                                NodeNixOptionFiltered_In ( n, vs )

                             else
                                NodeNixOptionFiltered_Out n
                            )
                            (tree |> Tree.children |> filterRecipeOptions route optionPath)
            )


filterRecipeOption : RouteRecipeOptions -> NixPath -> NixModuleOption -> Bool
filterRecipeOption route optionPath option =
    let
        searchPattern =
            route.routeRecipeOptions_searchPattern |> String.toLower

        -- Case Insensitive searchPattern
        option_name =
            optionPath |> joinNixPath |> String.toLower

        option_description =
            option.nixModuleOption_description |> String.toLower

        name_matches =
            String.contains searchPattern option_name

        desc_matches =
            String.contains searchPattern option_description
    in
    name_matches
        || desc_matches


paginateRecipeOptions : Model -> RouteRecipeOptions -> List a -> PagePagination a
paginateRecipeOptions model route =
    defaultPagePagination
        (let
            pagination =
                route.routeRecipeOptions_pagination
         in
         case model.model_page of
            Page_RecipeOptions page ->
                if
                    page.pageRecipeOptions_route.routeRecipeOptions_scope
                        == route.routeRecipeOptions_scope
                        && page.pageRecipeOptions_route.routeRecipeOptions_searchPattern
                        == route.routeRecipeOptions_searchPattern
                then
                    pagination

                else
                    { pagination | routePagination_current = Nothing }

            _ ->
                pagination
        )


listRecipeOptionsItems : InhRouteOptionsItem -> Tree NodeNixOptionFiltered -> List ( NixPath, NixModuleOption )
listRecipeOptionsItems inh tree =
    let
        name =
            tree |> Tree.label |> nodeNixOptionFiltered_name

        childrenInh =
            { inh | inhRouteRecipeOptionsItem_pathReversed = name :: inh.inhRouteRecipeOptionsItem_pathReversed }

        ( nodeChildrenLeaves, nodeChildrenBranches ) =
            tree |> Tree.children |> List.partition (Tree.children >> List.isEmpty)

        synLeaves =
            nodeChildrenLeaves |> List.map (listRecipeOptionsItems childrenInh)

        synBranches =
            nodeChildrenBranches |> List.map (listRecipeOptionsItems childrenInh)
    in
    List.concat
        [ if (synLeaves |> List.isEmpty) && (synBranches |> List.isEmpty) then
            case tree |> Tree.label of
                NodeNixOptionFiltered_In ( _, opts ) ->
                    opts
                        |> List.map (\opt -> ( pathRecipeOption inh tree, opt ))

                NodeNixOptionFiltered_Out _ ->
                    []

          else
            []
        , synLeaves |> List.concat
        , synBranches |> List.concat
        ]


type alias InhRouteOptionsItem =
    { inhRouteRecipeOptionsItem_pathReversed : NixPath
    }


pathRecipeOption : InhRouteOptionsItem -> Tree NodeNixOptionFiltered -> NixPath
pathRecipeOption inh tree =
    let
        name =
            tree |> Tree.label |> nodeNixOptionFiltered_name
    in
    (name :: inh.inhRouteRecipeOptionsItem_pathReversed) |> List.reverse
