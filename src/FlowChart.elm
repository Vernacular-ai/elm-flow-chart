module FlowChart exposing (Model, Msg, addNode, init, subscriptions, update, view)

import Browser
import Dict exposing (Dict)
import DraggableTypes exposing (DraggableTypes(..))
import FlowChart.Types exposing (FCCanvas, FCLink, FCNode, FCPort, Position)
import Html exposing (..)
import Html.Attributes as A
import Link
import Node
import Utils.CmdExtra as CmdExtra
import Utils.Draggable as Draggable



-- MODEL


type alias Model =
    { position : Position
    , nodes : Dict String FCNode
    , links : List FCLink
    , currentlyDragging : DraggableTypes
    , dragState : Draggable.DragState
    , nodeMap : String -> Html Msg
    }


type Msg
    = DragMsg (Draggable.Msg DraggableTypes)
    | OnDragBy Position
    | OnDragStart DraggableTypes
    | OnDragEnd
    | AddNode FCNode
    | RemoveNode FCNode
    | RemoveLink FCLink


init : FCCanvas -> (String -> Html Msg) -> Model
init canvas nodeMap =
    { position = canvas.position
    , nodes = Dict.fromList (List.map (\n -> ( n.id, n )) canvas.nodes)
    , links = canvas.links
    , currentlyDragging = None
    , dragState = Draggable.init
    , nodeMap = nodeMap
    }


addNode : FCNode -> Cmd Msg
addNode newNode =
    CmdExtra.message (AddNode newNode)



-- SUB


subscriptions : Model -> Sub Msg
subscriptions model =
    Draggable.subscriptions DragMsg model.dragState



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg mod =
    case msg of
        DragMsg dragMsg ->
            Draggable.update dragEvent dragMsg mod

        OnDragStart currentlyDragging ->
            ( { mod | currentlyDragging = currentlyDragging }, Cmd.none )

        OnDragBy deltaPos ->
            case mod.currentlyDragging of
                DCanvas ->
                    ( { mod | position = updatePosition mod.position deltaPos }, Cmd.none )

                DNode node ->
                    let
                        updateNode mayBeNode =
                            case mayBeNode of
                                Nothing ->
                                    Nothing

                                Just n ->
                                    Just
                                        { n
                                            | position = updatePosition n.position deltaPos
                                        }
                    in
                    ( { mod | nodes = Dict.update node.id updateNode mod.nodes }, Cmd.none )

                DPort nodeId fcPort ->
                    ( mod, Cmd.none )

                None ->
                    ( mod, Cmd.none )

        OnDragEnd ->
            ( { mod | currentlyDragging = None }, Cmd.none )

        AddNode newNode ->
            ( { mod | nodes = Dict.insert newNode.id newNode mod.nodes }, Cmd.none )

        RemoveNode node ->
            ( { mod | nodes = Dict.remove node.id mod.nodes }, Cmd.none )

        RemoveLink link ->
            ( mod, Cmd.none )


view : Model -> List (Html.Attribute Msg) -> Html Msg
view mod canvasStyle =
    div
        ([ A.style "width" "700px"
         , A.style "height" "580px"
         , A.style "overflow" "hidden"
         , A.style "position" "fixed"
         , A.style "cursor" "move"
         , A.style "background-color" "lightgrey"
         , Draggable.enableDragging DCanvas DragMsg
         ]
            ++ canvasStyle
        )
        [ div
            [ A.style "width" "0px"
            , A.style "height" "0px"
            , A.style "position" "absolute"
            , A.style "left" (String.fromFloat mod.position.x ++ "px")
            , A.style "top" (String.fromFloat mod.position.y ++ "px")
            ]
            (List.map
                (\node ->
                    Node.viewNode node DragMsg (mod.nodeMap node.nodeType)
                )
                (Dict.values mod.nodes)
                ++ List.map (Link.viewLink mod.nodes) mod.links
            )
        ]



-- HELPER FUNCTIONS


dragEvent : Draggable.Event Msg DraggableTypes
dragEvent =
    { onDragStartListener = Just << OnDragStart
    , onDragByListener = Just << OnDragBy
    , onDragEndListener = Just OnDragEnd
    }


updatePosition : Position -> Position -> Position
updatePosition oldPos deltaPos =
    { x = oldPos.x + deltaPos.x, y = oldPos.y + deltaPos.y }
