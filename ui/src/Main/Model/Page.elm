module Main.Model.Page exposing (..)

import List.Extra as List
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Config.Package exposing (..)
import Main.Helpers.List as List
import Main.Helpers.Nix exposing (..)
import Main.Helpers.Tree exposing (Trees)
import Main.Model.Error exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Model.Route exposing (..)
import Set exposing (Set)


type Page
    = Page_App PageApp
    | Page_Apps PageApps
    | Page_Packages PagePackages
    | Page_RecipeOptions PageRecipeOptions


defaultPage : Page
defaultPage =
    Page_Apps (defaultPageApps defaultRoutePagination [])


isPageSearch : Page -> Bool
isPageSearch page =
    case page of
        Page_App _ ->
            False

        Page_Apps _ ->
            True

        Page_Packages _ ->
            True

        Page_RecipeOptions _ ->
            True


type alias PageApp =
    { pageApp_route : RouteApp
    , pageApp_app : App

    -- `Nothing` means that the `App` provides no `AppRuntime` at all.
    , pageApp_runtime : Maybe AppRuntime
    }


type alias PageApps =
    { pageApps_route : RouteApps
    , pageApps_pagination : PagePagination App
    }


defaultPageApps : RoutePagination -> List App -> PageApps
defaultPageApps routePagination apps =
    { pageApps_route = defaultRouteApps
    , pageApps_pagination = defaultPagePagination routePagination apps
    }


type alias PagePackages =
    { pagePackages_route : RoutePackages
    , pagePackages_pagination : PagePagination Package
    }


defaultPagePackages : RoutePagination -> List Package -> PagePackages
defaultPagePackages routePagination packages =
    { pagePackages_route = defaultRoutePackages
    , pagePackages_pagination = defaultPagePagination routePagination packages
    }


type alias PageRecipeOptions =
    { pageRecipeOptions_route : RouteRecipeOptions
    , pageRecipeOptions_pagination : PagePagination ( NixAttrPath, NixModuleOption )
    , pageRecipeOptions_trees : Trees NodeNixOption
    , pageRecipeOptions_unfolds : Set NixAttrPath
    }


type alias NodeNixOption =
    ( NixAttrName, NixModuleOption )


type NixModuleOptionFiltered
    = NixModuleOptionFiltered_In NixModuleOption
    | NixModuleOptionFiltered_Out


type alias PagePagination a =
    { pagePagination_current : Int
    , pagePagination_list : List (List a)
    , pagePagination_MaxSize : Int
    , pagePagination_last : Int
    }


previousPagePagination : PagePagination a -> Maybe (PagePagination a)
previousPagePagination pagePagination =
    if 1 < pagePagination.pagePagination_current then
        Just
            { pagePagination
                | pagePagination_current = pagePagination.pagePagination_current - 1
            }

    else
        Nothing


nextPagePagination : PagePagination a -> Maybe (PagePagination a)
nextPagePagination pagePagination =
    if pagePagination.pagePagination_current < pagePagination.pagePagination_last then
        Just
            { pagePagination
                | pagePagination_current = pagePagination.pagePagination_current + 1
            }

    else
        Nothing


defaultPagePagination : RoutePagination -> List a -> PagePagination a
defaultPagePagination routePagination items =
    let
        maxResultsPerPage =
            routePagination.routePagination_MaxSize |> Maybe.withDefault 12
    in
    { pagePagination_current = routePagination.routePagination_current |> Maybe.withDefault 1
    , pagePagination_list =
        items
            |> List.greedyGroupsOf maxResultsPerPage
    , pagePagination_MaxSize = maxResultsPerPage
    , pagePagination_last =
        items
            |> List.length
            |> (\x -> (toFloat x / toFloat maxResultsPerPage) |> ceiling)
            |> max 1
    }
