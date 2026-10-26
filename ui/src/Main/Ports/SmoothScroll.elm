port module Main.Ports.SmoothScroll exposing (scrollIntoView, scrollRow, scrollToAndHighlight)


port scrollToAndHighlight : String -> Cmd msg


port scrollIntoView : String -> Cmd msg


{-| `scrollRow { id, direction }` scrolls the element `id` horizontally by most of its width, backward when `direction` is negative.
-}
port scrollRow : { id : String, direction : Float } -> Cmd msg
