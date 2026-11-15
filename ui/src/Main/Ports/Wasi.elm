port module Main.Ports.Wasi exposing (Workdir, addWasiFiles, applyWasiEvent, onWasiEvent, removeWasiFile, runWasi, stopWasi, workdir)

import Json.Decode as Decode exposing (Decoder)
import Main.Config.App exposing (..)
import Main.Model exposing (..)


{-| The working directory of the WASI program of `app`.
JavaScript keeps the files of the working directory.
If `reset` is true, or if `app` is not the app of the last request,
the files are the `examples` again.
-}
type alias Workdir =
    { app : String
    , examples : List { name : String, url : String }
    , reset : Bool
    }


workdir : App -> BrowserRun -> Workdir
workdir app run =
    { app = app.app_name
    , examples =
        app.app_programs.appPrograms_runtimes.appProgramsRuntimes_browser.files
            |> List.map (\name -> { name = name, url = appWasmFileUrl app name })
    , reset = run.browserRun_files == Nothing
    }


{-| Run a WASI program in a Web Worker.
A new run stops the previous run.
-}
port runWasi : { url : String, program : String, args : String, stdin : String, workdir : Workdir } -> Cmd msg


{-| Add JavaScript `File` objects to the working directory.
The new files replace the files with the same names.
-}
port addWasiFiles : { workdir : Workdir, files : List Decode.Value } -> Cmd msg


port removeWasiFile : { workdir : Workdir, name : String } -> Cmd msg


port stopWasi : () -> Cmd msg


{-| Events of the WASI program:
`{ kind : "stdout" | "stderr", text : String }`,
`{ kind : "exit", code : Int }`,
`{ kind : "error", text : String }`
and `{ kind : "files", app : String, files : List { name : String, size : Int, url : String } }`.
The "stdout", "stderr" and "exit" events apply only while the program runs.
-}
port onWasiEvent : (Decode.Value -> msg) -> Sub msg


applyWasiEvent : Decode.Value -> BrowserRun -> BrowserRun
applyWasiEvent value run =
    case Decode.decodeValue decodeWasiEvent value of
        Ok (WasiEvent_Files app files) ->
            if app == run.browserRun_app then
                { run | browserRun_files = Just files }

            else
                run

        -- The errors of `addWasiFiles` and `removeWasiFile` occur when the program does not run.
        Ok (WasiEvent_Error text) ->
            { run | browserRun_status = BrowserRunStatus_Failed text }

        _ ->
            if run.browserRun_status == BrowserRunStatus_Running then
                applyRunEvent value run

            else
                run


applyRunEvent : Decode.Value -> BrowserRun -> BrowserRun
applyRunEvent value run =
    case Decode.decodeValue decodeWasiEvent value of
        Ok (WasiEvent_Files _ _) ->
            run

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
    | WasiEvent_Files String (List BrowserFile)


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

                    "files" ->
                        Decode.map2 WasiEvent_Files
                            (Decode.field "app" Decode.string)
                            (Decode.field "files"
                                (Decode.list
                                    (Decode.map3 BrowserFile
                                        (Decode.field "name" Decode.string)
                                        (Decode.field "size" Decode.int)
                                        (Decode.field "url" Decode.string)
                                    )
                                )
                            )

                    _ ->
                        Decode.fail ("Unknown WASI event: " ++ kind)
            )
