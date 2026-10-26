module Main.Model exposing (..)

import Dict
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Config.Pkg exposing (..)
import Main.Helpers.Nix exposing (..)
import Main.Model.Error exposing (..)
import Main.Model.Page exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Model.Route exposing (..)


type alias Model =
    { model_config : Config
    , model_search : Search
    , model_page : Page
    , model_errors : List Error
    , model_preferences : Preferences
    , model_navbarExpanded : Bool
    , model_RecipeOptions : RecipeOptions
    , model_askFeedback : Bool
    , model_searchFocused : Bool
    , model_weeklySeed : Int
    , model_ephemeralSeed : Int
    , model_appsSortDropdownOpen : Bool
    , model_browserRun : BrowserRun
    }


{-| State of the WASI program of the browser runtime.
Only one program runs at a time.
-}
type alias BrowserRun =
    { browserRun_app : AppName
    , browserRun_args : String
    , browserRun_stdin : String

    -- Output chunks, last chunk first.
    , browserRun_output : List ( BrowserRunStream, String )
    , browserRun_status : BrowserRunStatus
    }


type BrowserRunStream
    = BrowserRunStream_Stdout
    | BrowserRunStream_Stderr


type BrowserRunStatus
    = BrowserRunStatus_Idle
    | BrowserRunStatus_Running
    | BrowserRunStatus_Exited Int
    | BrowserRunStatus_Failed String


emptyBrowserRun : BrowserRun
emptyBrowserRun =
    { browserRun_app = ""
    , browserRun_args = ""
    , browserRun_stdin = ""
    , browserRun_output = []
    , browserRun_status = BrowserRunStatus_Idle
    }


{-| The state of the WASI program of `app`,
with the example of the recipe if the state is for an other app.
-}
getBrowserRun : Model -> App -> BrowserRun
getBrowserRun model app =
    if model.model_browserRun.browserRun_app == app.app_name then
        model.model_browserRun

    else
        let
            browser =
                app.app_programs.appPrograms_runtimes.appProgramsRuntimes_browser
        in
        { emptyBrowserRun
            | browserRun_app = app.app_name
            , browserRun_args = browser.args
            , browserRun_stdin = browser.stdin
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
