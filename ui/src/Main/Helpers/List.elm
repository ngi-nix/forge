module Main.Helpers.List exposing (..)

import List.Extra as List


{-| List index (subscript) operator, starting from 0.

Warning(performance): This function takes linear time in the index.

-}
at : Int -> List a -> Maybe a
at n xs =
    if n < 0 then
        Nothing

    else
        xs |> List.drop n |> List.head


dropLast : List a -> Maybe (List a)
dropLast =
    List.reverse >> List.tail >> Maybe.map List.reverse


type alias Assoc key value =
    List ( key, value )
