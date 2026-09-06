port module Main.Model.Preferences exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)


type alias Preferences =
    { preferences_install : PreferencesInstall
    , preferences_theme : PreferencesTheme
    , preferences_sort : PreferencesSort
    }


defaultPreferences : Preferences
defaultPreferences =
    { preferences_install = PreferencesInstall_NixFlakes
    , preferences_theme = PreferencesTheme_Light
    , preferences_sort = PreferencesSort_Random
    }


decodePreferences : Decoder Preferences
decodePreferences =
    Decode.map3
        Preferences
        (Decode.oneOf
            [ Decode.field "install" decodePreferencesInstall
            , Decode.succeed defaultPreferences.preferences_install
            ]
        )
        (Decode.oneOf
            [ Decode.field "theme" decodePreferencesTheme
            , Decode.succeed defaultPreferences.preferences_theme
            ]
        )
        (Decode.oneOf
            [ Decode.field "sort" decodePreferencesSort
            , Decode.succeed defaultPreferences.preferences_sort
            ]
        )


encodePreferences : Preferences -> Value
encodePreferences preferences =
    Encode.object
        [ ( "install", preferences.preferences_install |> encodePreferencesInstall )
        , ( "theme", preferences.preferences_theme |> encodePreferencesTheme )
        , ( "sort", preferences.preferences_sort |> encodePreferencesSort )
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


type PreferencesSort
    = PreferencesSort_Random
    | PreferencesSort_Alphabetical


decodePreferencesSort : Decoder PreferencesSort
decodePreferencesSort =
    Decode.string
        |> Decode.andThen
            (\s ->
                case s of
                    "default" ->
                        Decode.succeed PreferencesSort_Random

                    "random_weekly" ->
                        Decode.succeed PreferencesSort_Random

                    "random" ->
                        Decode.succeed PreferencesSort_Random

                    "alphabetical" ->
                        Decode.succeed PreferencesSort_Alphabetical

                    _ ->
                        Decode.fail <| "Invalid PreferencesSort: " ++ s
            )


encodePreferencesSort : PreferencesSort -> Value
encodePreferencesSort sort =
    Encode.string <|
        case sort of
            PreferencesSort_Random ->
                "random"

            PreferencesSort_Alphabetical ->
                "alphabetical"
