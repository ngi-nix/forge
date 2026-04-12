module Main.Helpers.List exposing (..)

import List.Extra as List
import Tuple exposing (first, second)


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


type alias Group key value =
    Assoc key (List value)


{-| `group xs` returns a list grouping values associated
in `xs` whose association keys are equals.
-}
group : Assoc key value -> Group key value
group =
    let
        loop : Group key value -> Assoc key value -> Group key value
        loop done todo =
            case todo of
                [] ->
                    done |> List.reverse

                ( key, _ ) :: _ ->
                    let
                        ( xOks, xKos ) =
                            todo
                                |> List.partition ((==) key << first)
                    in
                    loop (( key, xOks |> List.map second ) :: done) xKos
    in
    loop []
