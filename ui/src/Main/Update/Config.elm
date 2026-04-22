module Main.Update.Config exposing (..)

import Dict
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
import Main.Update.Focus exposing (..)
import Main.Update.Types exposing (..)


{-| `updateConfig up` populates `model_config` if empty, then runs `up`.
`up` is thus always run, and only after `model_config` has been loaded.
-}
getConfig : Updater -> Updater
getConfig up model =
    if Dict.isEmpty model.model_config.config_apps then
        ( model
        , Http.get
            { url = "forge-config.json"
            , expect =
                Http.expectJson
                    (\res ->
                        Update_Chain
                            [ Update_Config res
                            , Update_Updater up
                            ]
                    )
                    decodeConfig
            }
        )

    else
        model |> up
