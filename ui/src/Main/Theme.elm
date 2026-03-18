module Main.Theme exposing (Theme(..), cycleTheme, themeFromString, themeToString)


type Theme
    = Theme_Auto
    | Theme_Dark
    | Theme_Light


cycleTheme : Theme -> Theme
cycleTheme currentTheme =
    case currentTheme of
        Theme_Auto ->
            Theme_Light

        Theme_Light ->
            Theme_Dark

        Theme_Dark ->
            Theme_Auto


themeFromString : String -> Theme
themeFromString str =
    case str of
        "light" ->
            Theme_Light

        "dark" ->
            Theme_Dark

        _ ->
            Theme_Auto


themeToString : Theme -> String
themeToString theme =
    case theme of
        Theme_Light ->
            "light"

        Theme_Dark ->
            "dark"

        Theme_Auto ->
            "auto"
