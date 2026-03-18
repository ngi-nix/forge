module Main.Model exposing (..)

import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Error exposing (..)
import Main.Route exposing (..)
import Main.Theme exposing (Theme)


type alias Model =
    { model_config : Config
    , model_search : String
    , model_page : Page
    , model_errors : List Error
    , model_theme : Theme
    }


{-| A `Page` is located at a `Route`,
with more or less data than `Route`:

  - More data if viewing the `Page` requires more than provided in its address,
    eg. by querying the backend (eg. `pageApp_app`).

  - Less data if navigating away from the `Page` must persist that data,
    and thus be persisted in `Model` (eg. `model_search`).

-}
type Page
    = Page_Search
    | Page_App PageApp


type alias PageApp =
    { pageApp_route : RouteApp
    , pageApp_app : App
    }
