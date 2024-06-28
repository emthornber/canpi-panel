module LayoutJson exposing (..)

import Dict
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Model
import Panel


fetchLayout : Cmd Model.Msg
fetchLayout =
    Http.get
        { url = "/home/thornbem/Work/canpi-panel/server/panels/cagdemo.json"
        , expect = Http.expectJson Model.LoadLayout modelDecoder
        }



-- Json Decoders


modelDecoder : Decode.Decoder Model.Model
modelDecoder =
    Decode.succeed Model.Model
        |> required "cbusstates" decodeCbus
        |> required "layout" (Decode.maybe layoutDecoder)
        |> hardcoded Model.Loaded


layoutDecoder : Decode.Decoder Model.Layout
layoutDecoder =
    Decode.succeed Model.Layout
        |> required "panel" decodeDiagram
        |> required "controls" (Decode.list decodeControl)
        |> required "track" (Decode.list decodeTrack)
        |> required "turnouts" (Decode.list decodeTurnout)


decodeDiagram : Decode.Decoder Panel.Diagram
decodeDiagram =
    Decode.succeed Panel.Diagram
        |> required "width" Decode.int
        |> required "height" Decode.int
        |> required "tilesize" Decode.int
        |> required "colour" Decode.string
        |> required "margins" Decode.int
        |> required "border" Decode.int
        |> required "title" Decode.string


decodeCbus : Decode.Decoder Model.CBUSStateDict
decodeCbus =
    Decode.list (Decode.map2 Tuple.pair (Decode.field "name" Decode.string) cbusStateDecoder)
        |> Decode.map Dict.fromList


cbusStateDecoder : Decode.Decoder Model.CBUSState
cbusStateDecoder =
    Decode.map2 Model.CBUSState (Decode.maybe (Decode.field "event" Decode.string)) (Decode.field "state" Decode.string |> Decode.andThen oneBitDecoder)


oneBitDecoder : String -> Decode.Decoder Model.OneBit
oneBitDecoder bit =
    case bit of
        "ZERO" ->
            Decode.succeed Model.ZERO

        "ONE" ->
            Decode.succeed Model.ONE

        _ ->
            Decode.succeed Model.UNKN


decodeControl : Decode.Decoder Model.Control
decodeControl =
    Decode.succeed Model.Control
        |> required "tile" decodePosition
        |> required "name" Decode.string
        |> required "switch" (Decode.string |> Decode.andThen switchDecoder)
        |> required "action" (Decode.map Just Decode.string)
        |> required "tostate" (Decode.map Just decodeTwoInput)


decodePosition : Decode.Decoder ( Int, Int )
decodePosition =
    Decode.map2 Tuple.pair (Decode.field "x_coord" Decode.int) (Decode.field "y_coord" Decode.int)


switchDecoder : String -> Decode.Decoder Model.Actuator
switchDecoder switch =
    case switch of
        "Toggle" ->
            Decode.succeed Model.Toggle

        "PushButton" ->
            Decode.succeed Model.PushButton

        _ ->
            Decode.succeed Model.Toggle


decodeTwoInput : Decode.Decoder ( String, String )
decodeTwoInput =
    Decode.map2 Tuple.pair (Decode.field "normal" Decode.string) (Decode.field "reverse" Decode.string)


decodeTrack : Decode.Decoder Model.Track
decodeTrack =
    Decode.succeed Model.Track
        |> required "tile" decodePosition
        |> required "direction" (Decode.string |> Decode.andThen directionDecoder)
        |> optional "label" (Decode.map Just Decode.string) Nothing
        |> optional "tcstate" (Decode.map Just Decode.string) Nothing
        |> optional "spot" (Decode.map Just Decode.string) Nothing


directionDecoder : String -> Decode.Decoder Model.TrackDirection
directionDecoder direction =
    case direction of
        "EW" ->
            Decode.succeed Model.EW

        "NE" ->
            Decode.succeed Model.NE

        "NS" ->
            Decode.succeed Model.NS

        "NW" ->
            Decode.succeed Model.NW

        "SE" ->
            Decode.succeed Model.SE

        "SW" ->
            Decode.succeed Model.SW

        _ ->
            Decode.succeed Model.EW


decodeTurnout : Decode.Decoder Model.Turnout
decodeTurnout =
    Decode.succeed Model.Turnout
        |> required "tile" decodePosition
        |> required "name" Decode.string
        |> required "hand" (Decode.string |> Decode.andThen handDecoder)
        |> required "orientation" (Decode.string |> Decode.andThen facingDecoder)
        |> optional "tostate" (Decode.map Just decodeTwoInput) Nothing


handDecoder : String -> Decode.Decoder Model.TurnoutHand
handDecoder hand =
    case hand of
        "Left" ->
            Decode.succeed Model.Left

        "Right" ->
            Decode.succeed Model.Right

        "Wye" ->
            Decode.succeed Model.Wye

        _ ->
            Decode.succeed Model.Left


facingDecoder : String -> Decode.Decoder Model.TurnoutFacing
facingDecoder hand =
    case hand of
        "North" ->
            Decode.succeed Model.North

        "East" ->
            Decode.succeed Model.East

        "South" ->
            Decode.succeed Model.South

        "West" ->
            Decode.succeed Model.West

        _ ->
            Decode.succeed Model.North
