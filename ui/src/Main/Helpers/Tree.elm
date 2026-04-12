module Main.Helpers.Tree exposing (..)

import List.Extra as List
import Main.Helpers.List as List
import Tree exposing (Tree)
import Tuple exposing (first, second)


type alias Trees a =
    List (Tree a)


unfoldTrees : (seed -> ( node, List seed )) -> List seed -> Trees node
unfoldTrees f =
    f |> Tree.unfold |> List.map


type alias AssocPath key value =
    List.Assoc (List key) value


unflattenChart : AssocPath key value -> List (Tree ( key, List value ))
unflattenChart name2opt =
    name2opt
        |> groupByHead
        |> unfoldTrees
            (\( key, keyGroup ) ->
                let
                    seeds =
                        keyGroup |> groupByHead
                in
                ( ( key
                  , keyGroup
                        |> List.concatMap
                            (\( k, v ) ->
                                if k == [] then
                                    [ v ]

                                else
                                    []
                            )
                  )
                , seeds
                )
            )


{-| `groupByHead xs` groups `xs` by the `List.head` of its path
and tuples the `List.tail` of its path with its associated value.
-}
groupByHead : AssocPath key value -> List.Assoc key (AssocPath key value)
groupByHead inp =
    inp
        -- Extract the `List.head` of paths
        |> List.concatMap
            (\( path, value ) ->
                case path of
                    [] ->
                        []

                    keyHead :: keyTail ->
                        [ ( keyHead, ( keyTail, value ) ) ]
            )
        -- Group by `List.head` of paths
        |> List.groupWhile (\x y -> first x == first y)
        -- Rearrange the grouping to have a `List.Assoc`
        |> List.map (\( x, xs ) -> ( x |> first, x :: xs |> List.map second ))
