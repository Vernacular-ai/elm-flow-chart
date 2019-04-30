module Canvas exposing (Model, Msg(..), dragEvent, init, main, subscriptions, update, view)

import Browser
import Html exposing (..)
import Html.Attributes as A
import Types exposing (Position, FCNode)
import Utils.Draggable as Draggable
import Node


main : Program () Model Msg
main =
    Browser.element { init = init, view = view, update = update, subscriptions = subscriptions }



-- MODEL

type alias Model =
    { nodes : List (FCNode Msg)
    , viewPosition : Position
    , numberNodes : Int
    , dragState : Draggable.DragState ()
    }


type Msg
    = DragMsg (Draggable.Msg ())
    | OnDragBy Position
    | OnDragStart ()


init : () -> ( Model, Cmd Msg )
init _ =
    ( { nodes = [
            Node.createDefaultNode "0" (Position 10 10)
            , Node.createDefaultNode "1" (Position 500 100)
        ]
      , viewPosition = Position 0 0
      , numberNodes = 2
      , dragState = Draggable.init
      }
    , Cmd.none
    )



-- SUB


dragEvent : Draggable.Event Msg ()
dragEvent =
    { onDragStartListener = Just << OnDragStart
    , onDragByListener = Just << OnDragBy
    , onDragEndListener = Nothing
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    Draggable.subscriptions DragMsg model.dragState



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg mod =
    case msg of
        DragMsg dragMsg ->
            Draggable.update dragEvent dragMsg mod

        OnDragBy deltaPos ->
            ( { mod | viewPosition = updatePosition mod.viewPosition deltaPos }, Cmd.none )

        OnDragStart id ->
            ( mod, Cmd.none )


view : Model -> Html Msg
view mod =
    div
        [ A.id "fc-canvas"
        , A.style "width" "97%"
        , A.style "height" "580px"
        , A.style "overflow" "hidden"
        , A.style "position" "fixed"
        , A.style "cursor" "move"
        , A.style "background-color" "lightgray"
        , Draggable.enableDragging () DragMsg
        ]
        [ div
            [ A.style "width" "0px"
            , A.style "height" "0px"
            , A.style "position" "absolute"
            , A.style "left" (String.fromFloat mod.viewPosition.x ++ "px")
            , A.style "top" (String.fromFloat mod.viewPosition.y ++ "px")
            ]
            (List.map Node.viewNode mod.nodes)
        ]



-- HELPER FUNCTIONS


updatePosition : Position -> Position -> Position
updatePosition oldPos deltaPos =
    { x = oldPos.x + deltaPos.x, y = oldPos.y + deltaPos.y }
