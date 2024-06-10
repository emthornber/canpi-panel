module Main exposing (main)

import Browser
import CbusState
import Dict
import Html
import Html.Attributes as HtmlA
import LayoutJson
import Model
import Tile



-- Main code


view : Model.Model -> Html.Html Model.Msg
view model =
    Html.div [ HtmlA.class "content" ]
        [ Html.h1 [] [ Html.text "canweb-elm" ]
        , Tile.view model
        , CbusState.view model
        ]


main : Program () Model.Model Model.Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : () -> ( Model.Model, Cmd Model.Msg )
init () =
    ( Model.initialModel, LayoutJson.fetchLayout )


update : Model.Msg -> Model.Model -> ( Model.Model, Cmd Model.Msg )
update msg model =
    case msg of
        Model.LoadLayout (Ok config) ->
            ( { model | cbus = config.cbus, layout = config.layout, status = Model.Loaded }
            , Cmd.none
            )

        Model.LoadLayout (Err _) ->
            ( { model | status = Model.Failure "Failed to load" }
            , Cmd.none
            )

        Model.ClickedOneBit name ->
            ( { model | cbus = updateCBUS name model.cbus }
            , Cmd.none
            )


updateCBUS : String -> Model.CBUSStateDict -> Model.CBUSStateDict
updateCBUS name cbus =
    let
        newRecord =
            case Dict.get name cbus of
                Just v ->
                    Model.toggleOBState v

                Nothing ->
                    { event = Nothing, state = Model.UNKN }
    in
    Dict.union (Dict.singleton name newRecord) cbus


subscriptions : Model.Model -> Sub Model.Msg
subscriptions _ =
    Sub.none
