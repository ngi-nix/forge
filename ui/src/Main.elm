module Main exposing (main)

import AppUrl
import Browser
import Json.Decode
import Json.Encode
import Main.Config
import Main.Config.App exposing (..)
import Main.Model exposing (..)
import Main.Model.Page exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Model.Route exposing (..)
import Main.Subscriptions
import Main.Update exposing (..)
import Main.Update.Types exposing (..)
import Main.View
import Url


type alias Flags =
    { href : String
    , flags_preferences : Json.Encode.Value
    }


main : Program Flags Model Update
main =
    Browser.element
        { init = init
        , view = Main.View.view
        , update = Main.Update.update
        , subscriptions = Main.Subscriptions.subscriptions
        }


init : Flags -> ( Model, Cmd Update )
init flags =
    let
        model =
            { model_config = Main.Config.initConfig
            , model_search = defaultSearch
            , model_page = defaultPage
            , model_errors = []
            , model_preferences =
                flags.flags_preferences
                    |> Json.Decode.decodeValue decodePreferences
                    |> Result.withDefault defaultPreferences
            , model_navbarExpanded = False
            , model_RecipeOptions = defaultRecipeOptions
            }
    in
    case flags.href |> Url.fromString of
        Nothing ->
            ( model, Cmd.none )

        Just url ->
            model
                |> update
                    (Update_Navigation
                        { appUrl = url |> AppUrl.fromUrl
                        , state = Json.Encode.null
                        }
                    )
