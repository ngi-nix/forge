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
import Set exposing (Set)
import String
import Tree exposing (Tree)
import Tuple exposing (first, mapSecond)


updateRouteRecipeOptions : RouteRecipeOptions -> Updater
updateRouteRecipeOptions route =
    getRecipeOptions <|
        \model ->
            { model
                | model_page =
                    let
                        trees : Trees NodeNixOption
                        trees =
                            model.model_RecipeOptions.recipeOptions_available
                                |> nixModuleOptionsToTrees

                        unfolds : Set NixAttrPath
                        unfolds =
                            route.routeRecipeOptions_unfolds
                                |> Set.insert route.routeRecipeOptions_scope
                                |> (case route.routeRecipeOptions_focus of
                                        Just (RouteRecipeOptionsFocus_Option optionPath) ->
                                            Set.insert optionPath

                                        _ ->
                                            identity
                                   )

                        unfoldsWithAncestors : Set NixAttrPath
                        unfoldsWithAncestors =
                            unfolds
                                |> Set.toList
                                |> List.concatMap List.inits
                                |> Set.fromList
                    in
                    Page_RecipeOptions
                        { pageRecipeOptions_route = route
                        , pageRecipeOptions_pagination =
                            trees
                                |> scopeRecipeOptions route.routeRecipeOptions_scope
                                |> filterRecipeOptions route []
                                |> List.concatMap (listRecipeOptionsItems [])
                                |> paginateRecipeOptions model route
                        , pageRecipeOptions_unfolds = unfoldsWithAncestors
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


scopeRecipeOptions : NixAttrPath -> Trees ( NixAttrName, NixModuleOption ) -> Trees ( NixAttrName, NixModuleOptionFiltered )
scopeRecipeOptions path trees =
    case path of
        [] ->
            trees |> List.map (Tree.map (mapSecond NixModuleOptionFiltered_In))

        p :: ps ->
            trees
                |> List.concatMap
                    (\tree ->
                        if tree |> Tree.label |> first |> (==) p then
                            if ps == [] && (tree |> Tree.children |> (==) []) then
                                [ Tree.tree
                                    (tree |> Tree.label |> mapSecond NixModuleOptionFiltered_In)
                                    []
                                ]

                            else
                                [ Tree.tree
                                    ( tree |> Tree.label |> first, NixModuleOptionFiltered_Out )
                                    (tree |> Tree.children |> scopeRecipeOptions ps)
                                ]

                        else
                            []
                    )


filterRecipeOptions : RouteRecipeOptions -> NixAttrPath -> Trees ( NixAttrName, NixModuleOptionFiltered ) -> Trees ( NixAttrName, NixModuleOptionFiltered )
filterRecipeOptions route path trees =
    trees
        |> List.map
            (\tree ->
                case tree |> Tree.label of
                    ( seg, NixModuleOptionFiltered_Out ) ->
                        Tree.tree
                            ( seg, NixModuleOptionFiltered_Out )
                            (tree |> Tree.children |> filterRecipeOptions route (path ++ [ seg ]))

                    ( seg, NixModuleOptionFiltered_In option ) ->
                        let
                            optionPath =
                                path ++ [ seg ]
                        in
                        Tree.tree
                            (if filterRecipeOption route optionPath option then
                                ( seg, NixModuleOptionFiltered_In option )

                             else
                                ( seg, NixModuleOptionFiltered_Out )
                            )
                            (tree |> Tree.children |> filterRecipeOptions route optionPath)
            )


filterRecipeOption : RouteRecipeOptions -> NixAttrPath -> NixModuleOption -> Bool
filterRecipeOption route optionPath option =
    let
        searchPattern =
            route.routeRecipeOptions_searchPattern |> String.toLower

        -- Case Insensitive searchPattern
        option_name =
            optionPath |> joinNixAttrPath |> String.toLower

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


listRecipeOptionsItems :
    NixAttrPath
    -> Tree ( NixAttrName, NixModuleOptionFiltered )
    -> List ( NixAttrPath, NixModuleOption )
listRecipeOptionsItems parentPath tree =
    let
        ( attrName, filteredOption ) =
            tree |> Tree.label

        path =
            parentPath ++ [ attrName ]

        ( nodeChildrenLeaves, nodeChildrenBranches ) =
            tree |> Tree.children |> List.partition (Tree.children >> List.isEmpty)

        synLeaves =
            nodeChildrenLeaves |> List.map (listRecipeOptionsItems path)

        synBranches =
            nodeChildrenBranches |> List.map (listRecipeOptionsItems path)
    in
    List.concat
        [ if (synLeaves |> List.isEmpty) && (synBranches |> List.isEmpty) then
            case filteredOption of
                NixModuleOptionFiltered_In opt ->
                    [ ( path, opt ) ]

                NixModuleOptionFiltered_Out ->
                    []

          else
            []
        , synLeaves |> List.concat
        , synBranches |> List.concat
        ]
