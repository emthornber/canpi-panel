module Model exposing (..)

import Dict
import Http
import Json.Decode.Pipeline exposing (..)
import Panel


type Status
    = Failure String
    | Loading
    | Loaded


type Msg
    = LoadLayout (Result Http.Error Model)
    | ClickedOneBit String


type alias Model =
    { cbus : CBUSStateDict
    , layout : Maybe Layout
    , status : Status
    }


type alias Layout =
    { panel : Panel.Diagram
    , sw : List Control
    , tr : List Track
    , to : List Turnout
    }


initialModel : Model
initialModel =
    { cbus = Dict.empty
    , layout = Nothing
    , status = Loading
    }


initialLayout : Layout
initialLayout =
    { panel = Panel.defaultDiagram
    , sw = controls
    , tr = tracks
    , to = turnouts
    }



-- Helper function to translate tile row and column numbers into x y coordinates


translateTile : ( Int, Int ) -> String
translateTile coords =
    let
        tiles =
            case initialModel.layout of
                Just layout ->
                    layout.panel.tiles

                Nothing ->
                    initialLayout.panel.tiles

        margins =
            case initialModel.layout of
                Just layout ->
                    layout.panel.margins

                Nothing ->
                    initialLayout.panel.margins

        x =
            ((Tuple.first coords - 1) * tiles) + (tiles // 2) + margins

        y =
            ((Tuple.second coords - 1) * tiles) + (tiles // 2) + margins
    in
    String.join " " [ "translate(", String.fromInt x, String.fromInt y, ")" ]



-- CBUS states


type OneBit
    = UNKN
    | ZERO
    | ONE


type alias TwoBit =
    ( OneBit, OneBit )


type alias CBUSState =
    { event : Maybe String, state : OneBit }


type alias CBUSStateDict =
    Dict.Dict String CBUSState


getOBState : Maybe String -> CBUSStateDict -> OneBit
getOBState name cbus =
    let
        getState : Maybe String -> Maybe CBUSState
        getState value =
            case value of
                Just key ->
                    case Dict.get key cbus of
                        Just record ->
                            Just record

                        _ ->
                            Nothing

                _ ->
                    Nothing

        getOneBit : Maybe CBUSState -> OneBit
        getOneBit state =
            case state of
                Just value ->
                    value.state

                Nothing ->
                    UNKN
    in
    getOneBit <| getState name


setOBState : CBUSStateDict -> Maybe String -> OneBit -> CBUSStateDict
setOBState cbus name newState =
    let
        getState : Maybe String -> Maybe CBUSState
        getState value =
            case value of
                Just key ->
                    case Dict.get key cbus of
                        Just record ->
                            Just record

                        _ ->
                            Nothing

                _ ->
                    Nothing

        getOneBit : Maybe CBUSState -> OneBit
        getOneBit state =
            case state of
                Just value ->
                    value.state

                Nothing ->
                    UNKN
    in
    -- Dict.update name (\rec -> { rec | state = newState }) cbus
    cbus


toggleOBState : CBUSState -> CBUSState
toggleOBState v =
    let
        newOB : OneBit -> OneBit
        newOB oldOB =
            case oldOB of
                ZERO ->
                    ONE

                ONE ->
                    ZERO

                UNKN ->
                    ZERO
    in
    { v | state = newOB v.state }


cbusStates : CBUSStateDict
cbusStates =
    Dict.fromList
        [ ( "TCAA", CBUSState (Just "N5E3") UNKN )
        , ( "TCBA", CBUSState (Just "N5E2") ZERO )
        , ( "TCBB", CBUSState (Just "N6E2") ZERO )
        , ( "TCCA", CBUSState (Just "N5E1") ONE )
        , ( "TCCB", CBUSState (Just "N6E2") ONE )
        , ( "TCDA", CBUSState (Just "N7E3") ZERO )
        , ( "101", CBUSState (Just "N5E5") UNKN )
        , ( "101N", CBUSState (Just "N5E6") UNKN )
        , ( "101R", CBUSState (Just "N5E7") UNKN )
        , ( "102", CBUSState (Just "N6E5") ZERO )
        , ( "102N", CBUSState (Just "N6E6") ONE )
        , ( "102R", CBUSState (Just "N6E7") ZERO )
        , ( "103", CBUSState (Just "N6E5") ONE )
        , ( "103N", CBUSState (Just "N7E6") ZERO )
        , ( "103R", CBUSState (Just "N7E7") ONE )
        , ( "104", CBUSState (Just "N6E5") ONE )
        , ( "104N", CBUSState (Just "N7E6") ZERO )
        , ( "104R", CBUSState (Just "N7E7") ZERO )
        , ( "105", CBUSState (Just "N6E5") ONE )
        , ( "105N", CBUSState (Just "N7E6") ONE )
        , ( "105R", CBUSState (Just "N7E7") ONE )
        ]



-- Controls


type Actuator
    = Toggle
    | PushButton


type alias Control =
    { coords : ( Int, Int ), name : String, switch : Actuator, action : Maybe String, state : Maybe ( String, String ) }


controls : List Control
controls =
    [ Control ( 6, 5 ) "101" Toggle (Just "101") (Just ( "101N", "101R" ))
    , Control ( 7, 5 ) "102" Toggle (Just "102") (Just ( "102N", "102R" ))
    , Control ( 8, 5 ) "103" Toggle (Just "103") (Just ( "103N", "103R" ))
    , Control ( 9, 5 ) "104" Toggle (Just "104") (Just ( "104N", "104R" ))
    , Control ( 10, 5 ) "105" Toggle (Just "105") (Just ( "105N", "105R" ))
    ]



-- Track


type TrackDirection
    = EW
    | NE
    | NS
    | NW
    | SE
    | SW


type alias Track =
    { coords : ( Int, Int ), direction : TrackDirection, label : Maybe String, state : Maybe String, spot : Maybe String }


tracks : List Track
tracks =
    [ Track ( 1, 5 ) EW Nothing Nothing Nothing
    , Track ( 2, 5 ) EW (Just "AA") (Just "TCAA") (Just "TCAA")
    , Track ( 3, 5 ) EW (Just "BA") (Just "TCBA") (Just "TCBA")
    , Track ( 4, 5 ) EW (Just "CA") (Just "TCCA") (Just "TCCA")
    , Track ( 1, 6 ) NS Nothing Nothing Nothing
    , Track ( 2, 6 ) NS (Just "AA") (Just "TCAA") Nothing
    , Track ( 3, 6 ) NS (Just "BA") (Just "TCBA") Nothing
    , Track ( 4, 6 ) NS (Just "CA") (Just "TCCA") Nothing
    , Track ( 1, 7 ) NE Nothing Nothing Nothing
    , Track ( 1, 7 ) SE Nothing Nothing Nothing
    , Track ( 1, 7 ) SW Nothing Nothing Nothing
    , Track ( 1, 7 ) NW Nothing Nothing (Just "TCBA")
    , Track ( 2, 7 ) NE (Just "AA") (Just "TCAA") (Just "TCAA")
    , Track ( 2, 7 ) SE (Just "AA") (Just "TCAA") Nothing
    , Track ( 2, 7 ) SW (Just "AA") (Just "TCAA") Nothing
    , Track ( 2, 7 ) NW (Just "AA") (Just "TCAA") Nothing
    , Track ( 3, 7 ) NE (Just "BA") (Just "TCBA") Nothing
    , Track ( 3, 7 ) SE (Just "BA") (Just "TCBA") (Just "TCBA")
    , Track ( 3, 7 ) SW (Just "BA") (Just "TCBA") Nothing
    , Track ( 3, 7 ) NW (Just "BA") (Just "TCBA") Nothing
    , Track ( 4, 7 ) NE (Just "CA") (Just "TCCA") Nothing
    , Track ( 4, 7 ) SE (Just "CA") (Just "TCCA") Nothing
    , Track ( 4, 7 ) SW (Just "CA") (Just "TCCA") (Just "TCCA")
    , Track ( 4, 7 ) NW (Just "CA") (Just "TCCA") Nothing
    ]



-- Turnouts


type TurnoutHand
    = TOLeft
    | TORight
    | TOWye


type TurnoutFacing
    = TONorth
    | TOEast
    | TOSouth
    | TOWest


type alias Turnout =
    { coords : ( Int, Int ), name : String, hand : TurnoutHand, orientation : TurnoutFacing, state : Maybe ( String, String ) }


turnouts : List Turnout
turnouts =
    [ Turnout ( 1, 1 ) "111" TOLeft TOWest Nothing
    , Turnout ( 2, 1 ) "121" TOLeft TONorth (Just ( "101N", "101R" ))
    , Turnout ( 3, 1 ) "121" TOLeft TOEast (Just ( "102N", "102R" ))
    , Turnout ( 4, 1 ) "121" TOLeft TOSouth (Just ( "103N", "103R" ))
    , Turnout ( 5, 1 ) "121" TOLeft TOWest (Just ( "105N", "105R" ))
    , Turnout ( 1, 2 ) "131" TORight TOWest Nothing
    , Turnout ( 2, 2 ) "131" TORight TONorth (Just ( "101N", "101R" ))
    , Turnout ( 3, 2 ) "131" TORight TOEast (Just ( "102N", "102R" ))
    , Turnout ( 4, 2 ) "131" TORight TOSouth (Just ( "103N", "103R" ))
    , Turnout ( 6, 4 ) "101" TORight TOWest (Just ( "101N", "101R" ))
    , Turnout ( 7, 4 ) "102" TORight TOWest (Just ( "102N", "102R" ))
    , Turnout ( 8, 4 ) "103" TORight TOWest (Just ( "103N", "103R" ))
    , Turnout ( 9, 4 ) "104" TORight TOWest (Just ( "104N", "104R" ))
    , Turnout ( 10, 4 ) "105" TORight TOWest (Just ( "105N", "105R" ))
    , Turnout ( 1, 3 ) "141" TOWye TOWest Nothing
    , Turnout ( 2, 3 ) "141" TOWye TONorth (Just ( "101N", "101R" ))
    , Turnout ( 3, 3 ) "141" TOWye TOEast (Just ( "102N", "102R" ))
    , Turnout ( 4, 3 ) "141" TOWye TOSouth (Just ( "103N", "103R" ))
    , Turnout ( 5, 3 ) "141" TOWye TOWest (Just ( "105N", "105R" ))
    ]
