port module Main.Ports.SmoothScroll exposing (scrollIntoView, scrollToAndHighlight)


port scrollToAndHighlight : String -> Cmd msg


port scrollIntoView : String -> Cmd msg
