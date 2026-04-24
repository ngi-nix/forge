module Main.Helpers.Tree exposing (..)

import List.Extra as List
import Main.Helpers.List as List
import Tree exposing (Tree)
import Tuple exposing (first, second)


type alias Trees a =
    List (Tree a)


{-| Like `Tree.unfold` but on `Trees`.
-}
unfoldTrees : (seed -> ( node, List seed )) -> List seed -> Trees node
unfoldTrees f =
    f |> Tree.unfold |> List.map


{-| Like `List.Assoc` but the key is a `List` of keys.
Eg. `[(["a", "b", "c"], 1), (["a", "b", "d"], 2)]`
-}
type alias AssocPath key value =
    List.Assoc (List key) value


{-| `chartToTrees chart` returns the `Trees`
formed by recursively gathering under the same `Tree` node
the associated `value`s sharing the same key prefix.

Eg.

    > chartToTrees [(["a", "b", "c"], 1), (["a", "b","d"], 2)]
    [Tree ("a",[]) [Tree ("b",[]) [Tree ("c",[1]) [],Tree ("d",[2]) []]]]

-}
chartToTrees : AssocPath key value -> Trees ( key, List value )
chartToTrees seedRoots =
    seedRoots
        -- Provision initial seeds by grouping on `List.head`.
        |> groupByHead
        |> unfoldTrees
            (\( seedKey, seedChildren ) ->
                ( ( seedKey
                  , seedChildren
                        |> List.concatMap
                            (\( childKey, childChildren ) ->
                                case childKey of
                                    -- Create a node when the end of the key path has been reached.
                                    [] ->
                                        [ childChildren ]

                                    --  Otherwise do not create any node.
                                    _ ->
                                        []
                            )
                  )
                , -- Provision the next seeds to unfold by grouping on `List.head` again.
                  seedChildren |> groupByHead
                )
            )


{-| `groupByHead xs` groups `xs` by the `List.head` of its path
and tuples the `List.tail` of its path with its associated value.
-}
groupByHead : AssocPath key value -> List.Assoc key (AssocPath key value)
groupByHead pathToValue =
    pathToValue
        -- Extract the `List.head` of paths.
        |> List.concatMap
            (\( path, value ) ->
                case path of
                    [] ->
                        []

                    keyHead :: keyTail ->
                        [ ( keyHead, ( keyTail, value ) ) ]
            )
        -- Group by `List.head` of paths.
        |> List.groupWhile (\x y -> first x == first y)
        -- Rearrange the grouping to have a `List.Assoc`.
        |> List.map (\( x, xs ) -> ( x |> first, x :: xs |> List.map second ))
