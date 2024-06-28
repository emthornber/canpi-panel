{-
   Testbed for embedded Svg usage creating Signal Panel tiles

   05 October, 2020 - E M Thornber
   Created
-}


module Tile exposing (view)

import Html
import Html.Attributes as HtmlA
import Model
import Panel
import Svg
import Svg.Attributes as SvgA


view : Model.Model -> Html.Html Model.Msg
view model =
    case model.layout of
        Just _ ->
            viewLayout model

        Nothing ->
            viewLoading


viewLayout : Model.Model -> Html.Html Model.Msg
viewLayout model =
    let
        layout =
            case model.layout of
                Just val ->
                    val

                Nothing ->
                    Model.initialLayout
    in
    Html.div [ HtmlA.class "panel" ]
        [ Html.h2 [] [ Html.text layout.panel.name ]
        , Svg.svg
            [ SvgA.id "tiles"
            , SvgA.width (Tuple.first (Panel.window layout.panel))
            , SvgA.height (Tuple.second (Panel.window layout.panel))
            ]
            (List.concat
                [ viewBackground layout.panel
                , viewTracks layout
                , viewTrackCircuits layout model.cbus
                , viewSpots layout model.cbus
                , viewTurnouts layout
                , viewLevers layout model.cbus
                , viewControls layout model.cbus
                ]
            )
        ]


viewLoading : Html.Html Model.Msg
viewLoading =
    Html.div [ HtmlA.class "panel" ]
        [ Html.h2 [] [ Html.text "Loading ..." ]
        ]



-- Background Tiles


viewBackground : Panel.Diagram -> List (Svg.Svg Model.Msg)
viewBackground diagram =
    let
        start =
            String.fromInt diagram.margins

        xStop =
            String.fromInt (diagram.margins + diagram.width * diagram.tiles)

        yStop =
            String.fromInt (diagram.margins + diagram.height * diagram.tiles)

        xGrid : Int -> List (Svg.Svg Model.Msg)
        xGrid linenum =
            let
                yBoth =
                    String.fromInt (diagram.margins + linenum * diagram.tiles)
            in
            [ Svg.line
                [ SvgA.x1 start, SvgA.y1 yBoth, SvgA.x2 xStop, SvgA.y2 yBoth ]
                []
            ]

        yGrid : Int -> List (Svg.Svg Model.Msg)
        yGrid linenum =
            let
                xBoth =
                    String.fromInt (diagram.margins + linenum * diagram.tiles)
            in
            [ Svg.line
                [ SvgA.x1 xBoth, SvgA.y1 start, SvgA.x2 xBoth, SvgA.y2 yStop ]
                []
            ]
    in
    [ Svg.rect
        [ SvgA.x (Panel.border diagram)
        , SvgA.y (Panel.border diagram)
        , SvgA.width (Tuple.first (Panel.edge diagram))
        , SvgA.height (Tuple.second (Panel.edge diagram))
        , SvgA.rx "0"
        , SvgA.fill "black"
        ]
        []
    , Svg.rect
        [ SvgA.x (Panel.margin diagram)
        , SvgA.y (Panel.margin diagram)
        , SvgA.width (Tuple.first (Panel.panel diagram))
        , SvgA.height (Tuple.second (Panel.panel diagram))
        , SvgA.rx "0"
        , SvgA.fill diagram.bkgFill
        ]
        []
    , Svg.g
        [ SvgA.stroke "black"
        ]
        (List.concat
            [ List.concatMap xGrid <| List.range 1 (diagram.height - 1)
            , List.concatMap yGrid <| List.range 1 (diagram.width - 1)
            ]
        )
    ]



-- Track Layout definitions


labelAttr : Model.Track -> ( Int, Int ) -> List (Svg.Attribute Model.Msg)
labelAttr track offset =
    let
        translation =
            "translate(" ++ String.fromInt (Tuple.first offset) ++ ", " ++ String.fromInt (Tuple.second offset) ++ ")"

        rotation =
            case track.direction of
                Model.NS ->
                    "rotate(-90)"

                Model.NE ->
                    "rotate(45)"

                Model.NW ->
                    "rotate(-45)"

                Model.SE ->
                    "rotate(135)"

                Model.SW ->
                    "rotate(-135)"

                Model.EW ->
                    "rotate(0)"
    in
    [ SvgA.fontFamily "monospace"
    , SvgA.fontSize "small"
    , SvgA.fill "black"
    , SvgA.stroke "none"
    , SvgA.x "0"
    , SvgA.y "4"
    , SvgA.textAnchor "middle"
    , SvgA.transform (String.join " " [ translation, rotation ])
    ]


trackFill : Model.Track -> String
trackFill track =
    case track.state of
        Just _ ->
            "black"

        Nothing ->
            "none"


viewTracks : Model.Layout -> List (Svg.Svg Model.Msg)
viewTracks layout =
    List.concat <| List.map viewTrack layout.tr


viewTrack : Model.Track -> List (Svg.Svg Model.Msg)
viewTrack track =
    case track.direction of
        Model.NS ->
            viewTrackOrthog track

        Model.EW ->
            viewTrackOrthog track

        _ ->
            viewTrackDiag track


viewTrackOrthog : Model.Track -> List (Svg.Svg Model.Msg)
viewTrackOrthog track =
    let
        rotate =
            case track.direction of
                Model.NS ->
                    "rotate(90)"

                _ ->
                    "rotate(0)"
    in
    [ Svg.g
        [ SvgA.transform (String.join " " [ Model.translateTile track.coords, rotate ]) ]
        [ Svg.polyline
            [ SvgA.fill (trackFill track)
            , SvgA.stroke "black"
            , SvgA.points "-30,5 30,5 30,-5 -30,-5 -30,5"
            ]
            []
        , Svg.text_
            (labelAttr track ( 0, 18 ))
            [ Svg.text (Maybe.withDefault "" track.label) ]
        ]
    ]


viewTrackDiag : Model.Track -> List (Svg.Svg Model.Msg)
viewTrackDiag track =
    let
        rotate =
            case track.direction of
                Model.SE ->
                    "rotate(90)"

                Model.SW ->
                    "rotate(180)"

                Model.NW ->
                    "rotate(-90)"

                _ ->
                    "rotate(0)"
    in
    [ Svg.g
        [ SvgA.transform (String.join " " [ Model.translateTile track.coords, rotate ]) ]
        [ Svg.polyline
            [ SvgA.fill (trackFill track)
            , SvgA.stroke "black"
            , SvgA.points "5,-30 30,-5 30,5 -5,-30 5,-30"
            ]
            []
        , Svg.text_
            (labelAttr track ( 0, -5 ))
            [ Svg.text (Maybe.withDefault "" track.label) ]
        ]
    ]



-- Track Circuit State definitions


tcFill : Model.OneBit -> String
tcFill status =
    case status of
        Model.UNKN ->
            "grey"

        Model.ZERO ->
            "white"

        Model.ONE ->
            "cyan"


viewTrackCircuits : Model.Layout -> Model.CBUSStateDict -> List (Svg.Svg Model.Msg)
viewTrackCircuits layout cbus =
    List.concat <|
        List.map (viewTC cbus) <|
            List.filter
                (\track ->
                    case track.state of
                        Just _ ->
                            True

                        Nothing ->
                            False
                )
                layout.tr


viewTC : Model.CBUSStateDict -> Model.Track -> List (Svg.Svg Model.Msg)
viewTC cbus track =
    case track.direction of
        Model.NS ->
            viewTCOrtho track <| tcFill <| Model.getOBState track.state cbus

        Model.EW ->
            viewTCOrtho track <| tcFill <| Model.getOBState track.state cbus

        _ ->
            viewTCDiag track <| tcFill <| Model.getOBState track.state cbus


viewTCOrtho : Model.Track -> String -> List (Svg.Svg Model.Msg)
viewTCOrtho track status =
    let
        rotate =
            case track.direction of
                Model.NS ->
                    "rotate(90)"

                _ ->
                    "rotate(0)"
    in
    [ Svg.g
        [ SvgA.fill status
        , SvgA.stroke status
        , SvgA.transform (String.join " " [ Model.translateTile track.coords, rotate ])
        ]
        [ Svg.rect
            [ SvgA.x "-23"
            , SvgA.y "-2"
            , SvgA.width "16"
            , SvgA.height "4"
            , SvgA.rx "2"
            ]
            []
        , Svg.rect
            [ SvgA.x "7"
            , SvgA.y "-2"
            , SvgA.width "16"
            , SvgA.height "4"
            , SvgA.rx "2"
            ]
            []
        ]
    ]


viewTCDiag : Model.Track -> String -> List (Svg.Svg Model.Msg)
viewTCDiag track status =
    let
        rotate =
            case track.direction of
                Model.SE ->
                    "rotate(135)"

                Model.SW ->
                    "rotate(-135)"

                Model.NW ->
                    "rotate(-45)"

                _ ->
                    "rotate(45)"
    in
    [ Svg.rect
        [ SvgA.x "-8"
        , SvgA.y "-23.25"
        , SvgA.width "16"
        , SvgA.height "4"
        , SvgA.rx "2"
        , SvgA.fill status
        , SvgA.stroke status
        , SvgA.transform (String.join " " [ Model.translateTile track.coords, rotate ])
        ]
        []
    ]



-- Indicator State definitions (Spot detectors) e.g. Stop boards, Limits of Shunt, Platform stops


spotFill : Model.OneBit -> String
spotFill spot =
    case spot of
        Model.UNKN ->
            "grey"

        Model.ZERO ->
            "white"

        Model.ONE ->
            "green"


viewSpots : Model.Layout -> Model.CBUSStateDict -> List (Svg.Svg Model.Msg)
viewSpots layout cbus =
    List.concat <|
        List.map (viewSpot cbus) <|
            List.filter
                (\track ->
                    case track.spot of
                        Just _ ->
                            True

                        Nothing ->
                            False
                )
                layout.tr


viewSpot : Model.CBUSStateDict -> Model.Track -> List (Svg.Svg Model.Msg)
viewSpot cbus track =
    case track.direction of
        Model.NS ->
            viewSpotOrtho track <| spotFill <| Model.getOBState track.spot cbus

        Model.EW ->
            viewSpotOrtho track <| spotFill <| Model.getOBState track.spot cbus

        _ ->
            viewSpotDiag track <| spotFill <| Model.getOBState track.spot cbus


viewSpotOrtho : Model.Track -> String -> List (Svg.Svg Model.Msg)
viewSpotOrtho track spot =
    let
        rotate =
            case track.direction of
                Model.NS ->
                    "rotate(90)"

                _ ->
                    "rotate(0)"
    in
    [ Svg.g
        [ SvgA.fill spot
        , SvgA.stroke spot
        , SvgA.transform (String.join " " [ Model.translateTile track.coords, rotate ])
        ]
        [ Svg.rect
            [ SvgA.x "-10"
            , SvgA.y "-12"
            , SvgA.width "20"
            , SvgA.height "3"
            , SvgA.rx "2"
            ]
            []
        ]
    ]


viewSpotDiag : Model.Track -> String -> List (Svg.Svg Model.Msg)
viewSpotDiag track spot =
    let
        rotate =
            case track.direction of
                Model.SE ->
                    "rotate(135)"

                Model.SW ->
                    "rotate(-135)"

                Model.NW ->
                    "rotate(-45)"

                _ ->
                    "rotate(45)"
    in
    [ Svg.rect
        [ SvgA.x "-7"
        , SvgA.y "-31"
        , SvgA.width "14"
        , SvgA.height "3"
        , SvgA.rx "2"
        , SvgA.fill spot
        , SvgA.stroke spot
        , SvgA.transform (String.join " " [ Model.translateTile track.coords, rotate ])
        ]
        []
    ]



-- Turnout Settings definitions
---- Convert double bit state into colours


textAttr : Model.Turnout -> ( Int, Int ) -> List (Svg.Attribute Model.Msg)
textAttr turnout offset =
    let
        translation =
            "translate(" ++ String.fromInt (Tuple.first offset) ++ ", " ++ String.fromInt (Tuple.second offset) ++ ")"

        rotation =
            case turnout.orientation of
                Model.North ->
                    "rotate(180)"

                Model.East ->
                    "rotate(180)"

                Model.South ->
                    "rotate(0)"

                Model.West ->
                    "rotate(0)"
    in
    [ SvgA.fontFamily "monospace"
    , SvgA.fontSize "small"
    , SvgA.fill "black"
    , SvgA.stroke "none"
    , SvgA.x "0"
    , SvgA.y "4"
    , SvgA.textAnchor "middle"
    , SvgA.transform (String.join " " [ translation, rotation ])
    ]


turnoutFill : Model.Turnout -> String
turnoutFill turnout =
    case turnout.state of
        Just _ ->
            "black"

        Nothing ->
            "none"


turnoutRotation : Model.Turnout -> String
turnoutRotation turnout =
    case turnout.orientation of
        Model.North ->
            "rotate(90)"

        Model.East ->
            "rotate(180)"

        Model.South ->
            "rotate(-90)"

        Model.West ->
            "rotate(0)"


viewTurnouts : Model.Layout -> List (Svg.Svg Model.Msg)
viewTurnouts layout =
    List.concat <| List.map viewTurnout layout.to


viewTurnout : Model.Turnout -> List (Svg.Svg Model.Msg)
viewTurnout turnout =
    case turnout.hand of
        Model.Left ->
            viewLeft turnout

        Model.Right ->
            viewRight turnout

        Model.Wye ->
            viewWye turnout


viewLeft : Model.Turnout -> List (Svg.Svg Model.Msg)
viewLeft turnout =
    [ Svg.g
        [ SvgA.fill (turnoutFill turnout)
        , SvgA.stroke "black"
        , SvgA.transform (String.join " " [ Model.translateTile turnout.coords, turnoutRotation turnout ])
        ]
        [ Svg.polyline
            [ SvgA.points "-30,5 30,5 30,-5 -30,-5 -30,5"
            ]
            []
        , Svg.polyline
            [ SvgA.points "-5,30 5,30 28,7 18,7 -5,30"
            ]
            []
        , Svg.text_
            (textAttr turnout ( 0, -18 ))
            [ Svg.text turnout.name ]
        ]
    ]


viewRight : Model.Turnout -> List (Svg.Svg Model.Msg)
viewRight turnout =
    [ Svg.g
        [ SvgA.fill (turnoutFill turnout)
        , SvgA.stroke "black"
        , SvgA.transform (String.join " " [ Model.translateTile turnout.coords, turnoutRotation turnout ])
        ]
        [ Svg.polyline
            [ SvgA.points "-30,5 30,5 30,-5 -30,-5 -30,5"
            ]
            []
        , Svg.polyline
            [ SvgA.points "-5,-30 5,-30 28,-7 18,-7 -5,-30"
            ]
            []
        , Svg.text_
            (textAttr turnout ( 0, 18 ))
            [ Svg.text turnout.name ]
        ]
    ]


viewWye : Model.Turnout -> List (Svg.Svg Model.Msg)
viewWye turnout =
    [ Svg.g
        [ SvgA.fill (turnoutFill turnout)
        , SvgA.stroke "black"
        , SvgA.transform (String.join " " [ Model.translateTile turnout.coords, turnoutRotation turnout ])
        ]
        [ Svg.polyline
            [ SvgA.points "0,5 30,5 30,-5 0,-5 0,5"
            ]
            []
        , Svg.polyline
            [ SvgA.points "-5,30 5,30 28,7 18,7 -5,30"
            ]
            []
        , Svg.polyline
            [ SvgA.points "-5,-30 5,-30 28,-7 18,-7 -5,-30"
            ]
            []
        , Svg.text_
            (textAttr turnout ( -15, 0 ))
            [ Svg.text turnout.name ]
        ]
    ]



-- Lever State definitions


leverFill : Model.TwoBit -> ( String, String )
leverFill double =
    case double of
        ( Model.UNKN, _ ) ->
            ( "grey", "grey" )

        ( _, Model.UNKN ) ->
            ( "grey", "grey" )

        ( Model.ZERO, Model.ZERO ) ->
            ( "none", "none" )

        ( Model.ONE, Model.ZERO ) ->
            ( "white", "none" )

        ( Model.ZERO, Model.ONE ) ->
            ( "none", "white" )

        _ ->
            ( "red", "red" )


leverStroke : Model.TwoBit -> ( String, String )
leverStroke double =
    case double of
        ( Model.UNKN, _ ) ->
            ( "grey", "grey" )

        ( _, Model.UNKN ) ->
            ( "grey", "grey" )

        ( Model.ZERO, Model.ZERO ) ->
            ( "white", "white" )

        ( Model.ONE, Model.ZERO ) ->
            ( "none", "white" )

        ( Model.ZERO, Model.ONE ) ->
            ( "white", "none" )

        _ ->
            ( "red", "red" )


viewLevers : Model.Layout -> Model.CBUSStateDict -> List (Svg.Svg Model.Msg)
viewLevers layout cbus =
    List.concat <|
        List.map (viewLever cbus) <|
            List.filter
                (\turnout ->
                    case turnout.state of
                        Just _ ->
                            True

                        Nothing ->
                            False
                )
                layout.to


viewLever : Model.CBUSStateDict -> Model.Turnout -> List (Svg.Svg Model.Msg)
viewLever cbus turnout =
    let
        getTON : Maybe ( String, String ) -> Maybe String
        getTON state =
            case state of
                Just value ->
                    Just (Tuple.first value)

                _ ->
                    Nothing

        getTOR : Maybe ( String, String ) -> Maybe String
        getTOR state =
            case state of
                Just value ->
                    Just (Tuple.second value)

                _ ->
                    Nothing

        status =
            ( Model.getOBState (getTON turnout.state) cbus, Model.getOBState (getTOR turnout.state) cbus )
    in
    case turnout.hand of
        Model.Left ->
            viewLeverLeft turnout (leverStroke status) (leverFill status) (turnoutRotation turnout)

        Model.Right ->
            viewLeverRight turnout (leverStroke status) (leverFill status) (turnoutRotation turnout)

        Model.Wye ->
            viewLeverWye turnout (leverStroke status) (leverFill status) (turnoutRotation turnout)


viewLeverLeft : Model.Turnout -> ( String, String ) -> ( String, String ) -> String -> List (Svg.Svg Model.Msg)
viewLeverLeft turnout stroke fill rotation =
    [ Svg.g
        [ SvgA.transform (String.join " " [ Model.translateTile turnout.coords, rotation ])
        ]
        [ Svg.rect
            [ SvgA.x "-23"
            , SvgA.y "-2"
            , SvgA.width "16"
            , SvgA.height "4"
            , SvgA.rx "2"
            , SvgA.stroke (Tuple.first stroke)
            , SvgA.fill (Tuple.first fill)
            ]
            []
        , Svg.rect
            [ SvgA.x "7"
            , SvgA.y "-2"
            , SvgA.width "16"
            , SvgA.height "4"
            , SvgA.rx "2"
            , SvgA.stroke (Tuple.first stroke)
            , SvgA.fill (Tuple.first fill)
            ]
            []
        , Svg.rect
            [ SvgA.x "-4"
            , SvgA.y "-23.25"
            , SvgA.width "16"
            , SvgA.height "4"
            , SvgA.rx "2"
            , SvgA.stroke (Tuple.second stroke)
            , SvgA.fill (Tuple.second fill)
            , SvgA.transform "rotate( 135 )"
            ]
            []
        ]
    ]


viewLeverRight : Model.Turnout -> ( String, String ) -> ( String, String ) -> String -> List (Svg.Svg Model.Msg)
viewLeverRight turnout stroke fill rotation =
    [ Svg.g
        [ SvgA.transform (String.join " " [ Model.translateTile turnout.coords, rotation ])
        ]
        [ Svg.rect
            [ SvgA.x "-23"
            , SvgA.y "-2"
            , SvgA.width "16"
            , SvgA.height "4"
            , SvgA.rx "2"
            , SvgA.stroke (Tuple.first stroke)
            , SvgA.fill (Tuple.first fill)
            ]
            []
        , Svg.rect
            [ SvgA.x "7"
            , SvgA.y "-2"
            , SvgA.width "16"
            , SvgA.height "4"
            , SvgA.rx "2"
            , SvgA.stroke (Tuple.first stroke)
            , SvgA.fill (Tuple.first fill)
            ]
            []
        , Svg.rect
            [ SvgA.x "-12"
            , SvgA.y "-23.25"
            , SvgA.width "16"
            , SvgA.height "4"
            , SvgA.rx "2"
            , SvgA.stroke (Tuple.second stroke)
            , SvgA.fill (Tuple.second fill)
            , SvgA.transform "rotate( 45 )"
            ]
            []
        ]
    ]


viewLeverWye : Model.Turnout -> ( String, String ) -> ( String, String ) -> String -> List (Svg.Svg Model.Msg)
viewLeverWye turnout stroke fill rotation =
    let
        centreInd : ( String, String ) -> String
        centreInd double =
            case double of
                ( "grey", _ ) ->
                    "grey"

                ( _, "grey" ) ->
                    "grey"

                ( "red", "red" ) ->
                    "red"

                _ ->
                    "white"
    in
    [ Svg.g
        [ SvgA.transform (String.join " " [ Model.translateTile turnout.coords, rotation ])
        ]
        [ Svg.rect
            [ SvgA.x "-12"
            , SvgA.y "-23.25"
            , SvgA.width "16"
            , SvgA.height "4"
            , SvgA.rx "2"
            , SvgA.stroke (Tuple.first stroke)
            , SvgA.fill (Tuple.first fill)
            , SvgA.transform "rotate( 45 )"
            ]
            []
        , Svg.rect
            [ SvgA.x "15"
            , SvgA.y "-2"
            , SvgA.width "8"
            , SvgA.height "4"
            , SvgA.rx "2"
            , SvgA.stroke (centreInd stroke)
            , SvgA.fill (centreInd fill)
            ]
            []
        , Svg.rect
            [ SvgA.x "-4"
            , SvgA.y "-23.25"
            , SvgA.width "16"
            , SvgA.height "4"
            , SvgA.rx "2"
            , SvgA.stroke (Tuple.second stroke)
            , SvgA.fill (Tuple.second fill)
            , SvgA.transform "rotate( 135 )"
            ]
            []
        ]
    ]



-- Controls


viewControls : Model.Layout -> Model.CBUSStateDict -> List (Svg.Svg Model.Msg)
viewControls layout cbus =
    List.concat <| List.map (viewControl cbus) layout.sw


viewControl : Model.CBUSStateDict -> Model.Control -> List (Svg.Svg Model.Msg)
viewControl cbus control =
    case control.switch of
        Model.Toggle ->
            List.concat [ viewSwBkgd control, viewSwState control cbus ]

        _ ->
            []


viewSwBkgd : Model.Control -> List (Svg.Svg Model.Msg)
viewSwBkgd switch =
    [ Svg.g
        [ SvgA.transform (Model.translateTile switch.coords)
        ]
        [ Svg.circle
            [ SvgA.cx "0"
            , SvgA.cy "15"
            , SvgA.r "10"
            , SvgA.stroke "black"
            , SvgA.fill "black"
            ]
            []
        , Svg.circle
            [ SvgA.cx "-17"
            , SvgA.cy "-20"
            , SvgA.r "5"
            , SvgA.stroke "black"
            , SvgA.fill "none"
            ]
            []
        , Svg.circle
            [ SvgA.cx "17"
            , SvgA.cy "-20"
            , SvgA.r "5"
            , SvgA.stroke "black"
            , SvgA.fill "none"
            ]
            []
        , Svg.g
            [ SvgA.fontFamily "monospace"
            , SvgA.fontSize "small"
            ]
            [ Svg.text_
                [ SvgA.x "-17"
                , SvgA.y "5"
                , SvgA.textAnchor "middle"
                ]
                [ Svg.text "N" ]
            , Svg.text_
                [ SvgA.x "17"
                , SvgA.y "5"
                , SvgA.textAnchor "middle"
                ]
                [ Svg.text "R" ]
            , Svg.text_
                [ SvgA.x "0"
                , SvgA.y "-5"
                , SvgA.textAnchor "middle"
                ]
                [ Svg.text switch.name ]
            ]
        ]
    ]


viewSwState : Model.Control -> Model.CBUSStateDict -> List (Svg.Svg Model.Msg)
viewSwState switch cbus =
    List.concat [ viewKnob switch cbus, viewLamps switch cbus ]


viewKnob : Model.Control -> Model.CBUSStateDict -> List (Svg.Svg Model.Msg)
viewKnob switch cbus =
    let
        knobRotate : Model.OneBit -> String
        knobRotate action =
            case action of
                Model.UNKN ->
                    "rotate(180)"

                Model.ZERO ->
                    "rotate(-45)"

                Model.ONE ->
                    "rotate(45)"

        knobColour : Model.OneBit -> String
        knobColour action =
            case action of
                Model.UNKN ->
                    "black"

                Model.ZERO ->
                    "white"

                Model.ONE ->
                    "white"
    in
    [ Svg.g
        [ SvgA.transform (Model.translateTile switch.coords)
        ]
        [ Svg.polyline
            [ SvgA.fill "none"
            , SvgA.stroke (knobColour <| Model.getOBState switch.action cbus)
            , SvgA.strokeLinecap "round"
            , SvgA.strokeWidth "0.75"
            , SvgA.points "0,-9 5,-2 2,-2 2,8 -2,8 -2,-2 -5,-2 0,-9"
            , SvgA.transform (String.join " " [ "translate(0 15)", knobRotate <| Model.getOBState switch.action cbus ])
            ]
            []
        ]
    ]


viewLamps : Model.Control -> Model.CBUSStateDict -> List (Svg.Svg Model.Msg)
viewLamps switch cbus =
    let
        getLampN : Maybe ( String, String ) -> Maybe String
        getLampN state =
            case state of
                Just value ->
                    Just (Tuple.first value)

                _ ->
                    Nothing

        getLampR : Maybe ( String, String ) -> Maybe String
        getLampR state =
            case state of
                Just value ->
                    Just (Tuple.second value)

                _ ->
                    Nothing

        fill =
            leverFill ( Model.getOBState (getLampN switch.state) cbus, Model.getOBState (getLampR switch.state) cbus )

        stroke =
            leverStroke ( Model.getOBState (getLampN switch.state) cbus, Model.getOBState (getLampR switch.state) cbus )
    in
    [ Svg.g
        [ SvgA.transform (Model.translateTile switch.coords)
        ]
        [ Svg.circle
            [ SvgA.cx "-17"
            , SvgA.cy "-20"
            , SvgA.r "4.5"
            , SvgA.stroke (Tuple.first stroke)
            , SvgA.fill (Tuple.first fill)
            ]
            []
        , Svg.circle
            [ SvgA.cx "17"
            , SvgA.cy "-20"
            , SvgA.r "4.5"
            , SvgA.stroke (Tuple.second stroke)
            , SvgA.fill (Tuple.second fill)
            ]
            []
        ]
    ]
