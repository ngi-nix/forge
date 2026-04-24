module Main.Helpers.Json.Decode exposing (..)

import Json.Decode as Decode exposing (Decoder)


flipMap : Decoder a -> (a -> b) -> Decoder b
flipMap x f =
    Decode.map f x


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap =
    Decode.map2 (|>)
