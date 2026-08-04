module Main.Helpers.GfmAlert exposing (..)

import Html exposing (Html)
import Main.Icons exposing (iconChatLeftExclamation, iconExclamationOctagon, iconExclamationTriangle, iconInfoCircle, iconLightbulb)


type GfmAlert
    = NoteAlert
    | TipAlert
    | ImportantAlert
    | WarningAlert
    | CautionAlert


gfmAlertToInt : GfmAlert -> Int
gfmAlertToInt alert =
    case alert of
        NoteAlert ->
            -999

        TipAlert ->
            -998

        ImportantAlert ->
            -997

        WarningAlert ->
            -996

        CautionAlert ->
            -995


allGfmAlerts : List GfmAlert
allGfmAlerts =
    [ NoteAlert
    , TipAlert
    , ImportantAlert
    , WarningAlert
    , CautionAlert
    ]


intToGfmAlert : Int -> Maybe GfmAlert
intToGfmAlert int =
    allGfmAlerts
        |> List.filter (\alert -> gfmAlertToInt alert == int)
        |> List.head


gfmAlertPrefix : GfmAlert -> String
gfmAlertPrefix alert =
    case alert of
        NoteAlert ->
            "[!NOTE]"

        TipAlert ->
            "[!TIP]"

        ImportantAlert ->
            "[!IMPORTANT]"

        WarningAlert ->
            "[!WARNING]"

        CautionAlert ->
            "[!CAUTION]"


gfmAlertTitle : GfmAlert -> String
gfmAlertTitle alert =
    case alert of
        NoteAlert ->
            "Note"

        TipAlert ->
            "Tip"

        ImportantAlert ->
            "Important"

        WarningAlert ->
            "Warning"

        CautionAlert ->
            "Caution"


gfmAlertClass : GfmAlert -> String
gfmAlertClass alert =
    case alert of
        NoteAlert ->
            "markdown-alert-note"

        TipAlert ->
            "markdown-alert-tip"

        ImportantAlert ->
            "markdown-alert-important"

        WarningAlert ->
            "markdown-alert-warning"

        CautionAlert ->
            "markdown-alert-caution"


gfmAlertIcon : GfmAlert -> Html msg
gfmAlertIcon alert =
    case alert of
        NoteAlert ->
            iconInfoCircle

        TipAlert ->
            iconLightbulb

        ImportantAlert ->
            iconChatLeftExclamation

        WarningAlert ->
            iconExclamationTriangle

        CautionAlert ->
            iconExclamationOctagon


findGfmAlert : String -> Maybe GfmAlert
findGfmAlert text =
    allGfmAlerts
        |> List.filter (\alert -> String.startsWith (gfmAlertPrefix alert) text)
        |> List.head
