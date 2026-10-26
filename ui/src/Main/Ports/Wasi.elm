port module Main.Ports.Wasi exposing (applyWasiEvent, onWasiEvent, runWasi, stopWasi)

import Json.Decode as Decode exposing (Decoder)
import Main.Model exposing (..)


{-| Run a WASI program in a Web Worker.
A new run stops the previous run.
-}
port runWasi : { url : String, program : String, args : String, stdin : String } -> Cmd msg


port stopWasi : () -> Cmd msg


{-| Events of the WASI program:
`{ kind : "stdout" | "stderr", text : String }`,
`{ kind : "exit", code : Int }`
and `{ kind : "error", text : String }`.
-}
port onWasiEvent : (Decode.Value -> msg) -> Sub msg


applyWasiEvent : Decode.Value -> BrowserRun -> BrowserRun
applyWasiEvent value run =
    case Decode.decodeValue decodeWasiEvent value of
        Ok (WasiEvent_Output stream text) ->
            { run
                | browserRun_output =
                    case run.browserRun_output of
                        ( lastStream, lastText ) :: output ->
                            if lastStream == stream then
                                ( stream, lastText ++ text ) :: output

                            else
                                ( stream, text ) :: run.browserRun_output

                        [] ->
                            [ ( stream, text ) ]
            }

        Ok (WasiEvent_Exit code) ->
            { run | browserRun_status = BrowserRunStatus_Exited code }

        Ok (WasiEvent_Error text) ->
            { run | browserRun_status = BrowserRunStatus_Failed text }

        Err error ->
            { run | browserRun_status = BrowserRunStatus_Failed (Decode.errorToString error) }


type WasiEvent
    = WasiEvent_Output BrowserRunStream String
    | WasiEvent_Exit Int
    | WasiEvent_Error String


decodeWasiEvent : Decoder WasiEvent
decodeWasiEvent =
    Decode.field "kind" Decode.string
        |> Decode.andThen
            (\kind ->
                case kind of
                    "stdout" ->
                        Decode.map (WasiEvent_Output BrowserRunStream_Stdout) (Decode.field "text" Decode.string)

                    "stderr" ->
                        Decode.map (WasiEvent_Output BrowserRunStream_Stderr) (Decode.field "text" Decode.string)

                    "exit" ->
                        Decode.map WasiEvent_Exit (Decode.field "code" Decode.int)

                    "error" ->
                        Decode.map WasiEvent_Error (Decode.field "text" Decode.string)

                    _ ->
                        Decode.fail ("Unknown WASI event: " ++ kind)
            )
