module Main.Model exposing (..)

import Dict
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Config.Package exposing (..)
import Main.Error exposing (..)
import Main.Helpers.Nix exposing (..)
import Main.Model.Page exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Route exposing (..)


type alias Model =
    { model_config : Config
    , model_search : Search
    , model_page : Page
    , model_errors : List Error
    , model_preferences : Preferences
    , model_navbarExpanded : Bool
    , model_RecipeOptions : RecipeOptions
    }


type alias Search =
    String


defaultSearch : Search
defaultSearch =
    ""


type alias RecipeOptions =
    { recipeOptions_available : NixModuleOptions
    }


defaultRecipeOptions : RecipeOptions
defaultRecipeOptions =
    { recipeOptions_available = Dict.empty
    }
