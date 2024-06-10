module Panel exposing (Diagram, border, defaultDiagram, edge, margin, panel, window)


type alias Diagram =
    { width : Int
    , height : Int
    , tiles : Int
    , bkgFill : String
    , margins : Int
    , border : Int
    , name : String
    }


defaultDiagram : Diagram
defaultDiagram =
    { width = 13
    , height = 7
    , tiles = 60
    , bkgFill = "#a4b887"
    , margins = 10
    , border = 2
    , name = "Elm CBUS Test Patterns"
    }


window : Diagram -> ( String, String )
window diag =
    let
        calc : Int -> Diagram -> String
        calc num dim =
            String.fromInt ((num * dim.tiles) + (2 * dim.margins))
    in
    ( calc diag.width diag, calc diag.height diag )


edge : Diagram -> ( String, String )
edge diag =
    let
        calc : Int -> Diagram -> String
        calc num dim =
            String.fromInt ((num * dim.tiles) + (2 * dim.border))
    in
    ( calc diag.width diag, calc diag.height diag )


panel : Diagram -> ( String, String )
panel diag =
    let
        calc : Int -> Diagram -> String
        calc num dim =
            String.fromInt (num * dim.tiles)
    in
    ( calc diag.width diag, calc diag.height diag )


margin : Diagram -> String
margin diag =
    String.fromInt diag.margins


border : Diagram -> String
border diag =
    String.fromInt (diag.margins - diag.border)
