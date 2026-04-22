module Main.Update.Types exposing (Update(..), Updater)

import Browser.Dom as Dom
import Http
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Helpers.Nix exposing (..)
import Main.Model exposing (..)
import Main.Model.Error exposing (..)
import Main.Model.Page exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Model.Route exposing (..)
import Main.Ports.SmoothScroll exposing (..)
import Navigation


type alias Updater =
    Model -> ( Model, Cmd Update )


type Update
    = -- `Update_Chain us` left-folds `Update` in `us` on the `Model`.
      Update_Chain (List Update)
    | Update_CopyToClipboard String
    | Update_Config (Result Http.Error Config)
    | -- `Update_RecipeOptions res` loads the `res` of `updateRecipeOptions` into `model_RecipeOptions`.
      Update_RecipeOptions (Result Http.Error NixModuleOptions)
    | Update_Navigation Navigation.Event
    | Update_Route Route
    | Update_RouteWithoutNavigation Route
    | Update_RouteWithoutHistory Route
    | -- `Update_Updater up` simply applies `up` to the `Model`.
      -- Useful in a `Update_Chain` to defer `up` after some other updates.
      Update_Updater Updater
    | Update_ToggleNavBar
    | Update_CycleTheme
    | Update_Focus String
    | Update_SetPreferences Preferences
    | Update_FocusResult (Result Dom.Error ())
    | Update_AmbientKeyPress AmbientKeyState
    | Update_Search Search
    | Update_NoOp


type alias AmbientKeyState =
    { key : String
    , focusedTyping : Bool
    , hasModifier : Bool
    }
