module FlowChart exposing
    ( Model, Msg, FCEvent
    , init, subscriptions, update, view
    , addNode
    )

{-| This library aims to provide a flow chart builder in Elm.


# Definition

@docs Model, Msg


# Helpers

@docs init, subscriptions, update, view


# Functionalities

@docs addNode

-}

import Browser
import Dict exposing (Dict)
import Internal exposing (DraggableTypes(..), toPx)
import FlowChart.Types exposing (FCCanvas, FCLink, FCNode, FCPort, Vector2)
import Html exposing (Html, div)
import Html.Attributes as A
import Link
import Node
import Random
import Svg exposing (Svg, svg)
import Svg.Attributes as SA
import Utils.CmdExtra as CmdExtra
import Utils.Draggable as Draggable
import Utils.MathUtils as MathUtils
import Utils.RandomExtra as RandomExtra



-- MODEL


{-| flowchart model
-}
type alias Model =
    { position : Vector2
    , nodes : Dict String FCNode
    , links : Dict String Link.Model
    , currentlyDragging : DraggableTypes
    , dragState : Draggable.DragState
    , nodeMap : String -> Html Msg
    }


{-| flowchart message
-}
type Msg
    = DragMsg (Draggable.Msg DraggableTypes)
    | OnDragBy Vector2
    | OnDragStart DraggableTypes
    | OnDragEnd String String
    | AddNode FCNode
    | RemoveNode FCNode
    | AddLink FCLink String
    | RemoveLink FCLink


type alias FCEvent msg =
    { onCanvasClick : FCCanvas -> Maybe msg
    , onNodeClick : FCNode -> Maybe msg
    , onLinkClick : FCLink -> Maybe msg
    }


{-| init flowchart

    init fcCanvas nodeMap

-}
init : FCCanvas -> (String -> Html Msg) -> Model
init canvas nodeMap =
    { position = canvas.position
    , nodes = Dict.fromList (List.map (\n -> ( n.id, n )) canvas.nodes)
    , links = Dict.empty
    , currentlyDragging = None
    , dragState = Draggable.init
    , nodeMap = nodeMap
    }


{-| call to add node to canvas
-}
addNode : FCNode -> Cmd Msg
addNode newNode =
    CmdExtra.message (AddNode newNode)


{-| subscriptions
-}
subscriptions : Model -> Sub Msg
subscriptions model =
    Draggable.subscriptions DragMsg model.dragState


{-| call to update the canvas
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg mod =
    case msg of
        DragMsg dragMsg ->
            Draggable.update dragEvent dragMsg mod

        OnDragStart currentlyDragging ->
            let
                cCmd =
                    case currentlyDragging of
                        DPort nodeId portId linkId ->
                            let
                                p =
                                    { nodeId = nodeId, portId = portId }

                                newLink =
                                    { id = "", from = p, to = p }
                            in
                            Random.generate (AddLink newLink) (RandomExtra.randomString 6)

                        _ ->
                            Cmd.none
            in
            ( { mod | currentlyDragging = currentlyDragging }, cCmd )

        OnDragBy deltaPos ->
            case mod.currentlyDragging of
                DCanvas ->
                    ( { mod | position = MathUtils.addVector2 mod.position deltaPos }, Cmd.none )

                DNode node ->
                    let
                        updateNode fcNode =
                            { fcNode | position = MathUtils.addVector2 fcNode.position deltaPos }
                    in
                    ( { mod | nodes = Dict.update node.id (Maybe.map updateNode) mod.nodes }, Cmd.none )

                DPort nodeId portId linkId ->
                    let
                        updateLink link =
                            { link
                                | tempPosition =
                                    Just
                                        (MathUtils.addVector2
                                            (Maybe.withDefault (Vector2 0 0) link.tempPosition)
                                            deltaPos
                                        )
                            }
                    in
                    ( { mod | links = Dict.update linkId (Maybe.map updateLink) mod.links }, Cmd.none )

                None ->
                    ( mod, Cmd.none )

        OnDragEnd elementId parentId ->
            case mod.currentlyDragging of
                DPort nodeId portId linkId ->
                    if Dict.member parentId mod.nodes then
                        let
                            updateFcLink fcLink =
                                { fcLink | to = { nodeId = parentId, portId = elementId } }

                            updateLink link =
                                { link | tempPosition = Nothing, fcLink = updateFcLink link.fcLink }
                        in
                        ( { mod
                            | currentlyDragging = None
                            , links = Dict.update linkId (Maybe.map updateLink) mod.links
                          }
                        , Cmd.none
                        )

                    else
                        ( { mod
                            | currentlyDragging = None
                            , links = Dict.remove linkId mod.links
                          }
                        , Cmd.none
                        )

                _ ->
                    ( { mod | currentlyDragging = None }, Cmd.none )

        AddNode newNode ->
            ( { mod | nodes = Dict.insert newNode.id newNode mod.nodes }, Cmd.none )

        RemoveNode node ->
            ( { mod | nodes = Dict.remove node.id mod.nodes }, Cmd.none )

        AddLink fcLink linkId ->
            let
                newLink =
                    { fcLink = { fcLink | id = linkId }, tempPosition = Nothing }
            in
            ( { mod
                | links = Dict.insert linkId newLink mod.links
                , currentlyDragging = DPort fcLink.from.nodeId fcLink.from.portId linkId
              }
            , Cmd.none
            )

        RemoveLink fcLink ->
            ( { mod | links = Dict.remove fcLink.id mod.links }, Cmd.none )


{-| display the canvas
-}
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
            , A.style "left" (toPx mod.position.x)
            , A.style "top" (toPx mod.position.y)
            ]
            (List.map
                (\node ->
                    Node.viewNode node DragMsg (mod.nodeMap node.nodeType)
                )
                (Dict.values mod.nodes)
                ++ [ svg
                        [ SA.overflow "visible" ]
                        ( Internal.getArrowHead
                            ++ List.map (Link.viewLink mod.nodes) (Dict.values mod.links)
                        )
                   ]
            )
        ]



-- HELPER FUNCTIONS


dragEvent : Draggable.Event Msg DraggableTypes
dragEvent =
    { onDragStartListener = OnDragStart >> Just
    , onDragByListener = OnDragBy >> Just
    , onDragEndListener = \x -> \y -> Just (OnDragEnd x y)
    }
