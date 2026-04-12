module Main.View.Nix exposing (..)

import Html exposing (Html, code, text)
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Helpers.AppUrl exposing (..)
import Main.Helpers.Html exposing (..)
import Main.Helpers.Nix exposing (..)
import Main.Icons exposing (..)
import Main.Model exposing (..)
import Main.Model.Page exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Model.Route exposing (..)
import Main.Update exposing (..)
import Main.Update.Types exposing (..)
import Main.View.Page.App exposing (..)
import Main.View.Pagination exposing (..)


viewNixLiteralExpression : NixLiteralExpression -> Html Update
viewNixLiteralExpression lit =
    case lit.nixLiteralExpression_type of
        "literalExpression" ->
            code [] [ text lit.nixLiteralExpression_text ]

        _ ->
            text lit.nixLiteralExpression_text
