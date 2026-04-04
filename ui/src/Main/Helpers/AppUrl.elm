module Main.Helpers.AppUrl exposing (..)

import AppUrl exposing (..)


setFragment : Maybe String -> AppUrl -> AppUrl
setFragment frag url =
    { url | fragment = frag }
