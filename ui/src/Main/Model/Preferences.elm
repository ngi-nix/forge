port module Main.Model.Preferences exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)


type alias Preferences =
    { preferences_install : PreferencesInstall
    , preferences_theme : PreferencesTheme
    , preferences_feedbackDismissed : Bool
    }


defaultPreferences : Preferences
defaultPreferences =
    { preferences_install = PreferencesInstall_NixFlakes
    , preferences_theme = PreferencesTheme_Light
    , preferences_feedbackDismissed = False
    }


decodePreferences : Decoder Preferences
decodePreferences =
    Decode.map3
        Preferences
        (Decode.field "install"
            (Decode.oneOf
                [ decodePreferencesInstall
                , Decode.succeed defaultPreferences.preferences_install
                ]
            )
        )
        (Decode.field "theme"
            (Decode.oneOf
                [ decodePreferencesTheme
                , Decode.succeed defaultPreferences.preferences_theme
                ]
            )
        )
        (Decode.field "feedbackDismissed"
            (Decode.oneOf
                [ Decode.bool
                , Decode.succeed defaultPreferences.preferences_feedbackDismissed
                ]
            )
        )


encodePreferences : Preferences -> Value
encodePreferences preferences =
    Encode.object
        [ ( "install", preferences.preferences_install |> encodePreferencesInstall )
        , ( "theme", preferences.preferences_theme |> encodePreferencesTheme )
        , ( "feedbackDismissed", Encode.bool preferences.preferences_feedbackDismissed )
        ]


setPreferences : Preferences -> Cmd update
setPreferences prefs =
    prefs |> encodePreferences |> setPreferencesJson


port setPreferencesJson : Value -> Cmd update


type PreferencesInstall
    = PreferencesInstall_NixFlakes
    | PreferencesInstall_NixTraditional


decodePreferencesInstall : Decoder PreferencesInstall
decodePreferencesInstall =
    Decode.string
        |> Decode.andThen
            (\s ->
                case s of
                    "nix_flake" ->
                        Decode.succeed PreferencesInstall_NixFlakes

                    "nix_traditional" ->
                        Decode.succeed PreferencesInstall_NixTraditional

                    _ ->
                        Decode.fail <| "Invalid PreferencesInstall: " ++ s
            )


encodePreferencesInstall : PreferencesInstall -> Value
encodePreferencesInstall pref =
    Encode.string <|
        case pref of
            PreferencesInstall_NixFlakes ->
                "nix_flake"

            PreferencesInstall_NixTraditional ->
                "nix_traditional"


listPreferencesInstall : List PreferencesInstall
listPreferencesInstall =
    [ PreferencesInstall_NixFlakes
    , PreferencesInstall_NixTraditional
    ]


type PreferencesTheme
    = PreferencesTheme_Dark
    | PreferencesTheme_Light


cyclePreferencesTheme : PreferencesTheme -> PreferencesTheme
cyclePreferencesTheme currentTheme =
    case currentTheme of
        PreferencesTheme_Light ->
            PreferencesTheme_Dark

        PreferencesTheme_Dark ->
            PreferencesTheme_Light


decodePreferencesTheme : Decoder PreferencesTheme
decodePreferencesTheme =
    Decode.string
        |> Decode.andThen
            (\s ->
                case s of
                    "light" ->
                        Decode.succeed PreferencesTheme_Light

                    "dark" ->
                        Decode.succeed PreferencesTheme_Dark

                    _ ->
                        Decode.fail <| "Invalid PreferencesTheme: " ++ s
            )


encodePreferencesTheme : PreferencesTheme -> Value
encodePreferencesTheme theme =
    Encode.string <|
        case theme of
            PreferencesTheme_Light ->
                "light"

            PreferencesTheme_Dark ->
                "dark"
