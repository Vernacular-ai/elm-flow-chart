module Link exposing (Model, viewLink)

import Dict exposing (Dict)
import FlowChart.Types exposing (FCLink, FCNode, FCPort, Vector2)
import Html exposing (Html)
import Svg exposing (Svg, svg)
import Svg.Attributes as SA
import Utils.MathUtils as MathUtils


type alias Model =
    { fcLink : FCLink, tempPosition : Maybe Vector2 }


viewLink : Dict String FCNode -> Model -> Svg msg
viewLink nodes link =
    case calcPositions link nodes of
        Nothing ->
            Svg.line [] []

        Just ( startPos, endPos ) ->
            Svg.path
                [ SA.d (generatePath startPos endPos)
                , SA.stroke "cornflowerblue"
                , SA.strokeWidth "2"
                , SA.fill "none"
                , SA.markerEnd "url(#arrow)"
                ]
                []



-- HELPER FUNCTIONS


calcPositions : Model -> Dict String FCNode -> Maybe ( Vector2, Vector2 )
calcPositions link nodes =
    let
        fcLink =
            link.fcLink

        finalPositions : Vector2 -> Vector2 -> ( Vector2, Vector2 )
        finalPositions fromPos toPos =
            if fcLink.from.portId == fcLink.to.portId then
                ( fromPos
                , updatePosition fromPos (Maybe.withDefault (Vector2 0 0) link.tempPosition)
                )

            else
                ( fromPos, toPos )
    in
    Maybe.map2 finalPositions
        (getPortPosition fcLink.from.portId (Dict.get fcLink.from.nodeId nodes))
        (getPortPosition fcLink.to.portId (Dict.get fcLink.to.nodeId nodes))


getPortPosition : String -> Maybe FCNode -> Maybe Vector2
getPortPosition portId node =
    let
        addRelativePosition pos1 pos2 dim =
            { x = pos1.x + pos2.x * dim.x, y = pos1.y + pos2.y * dim.y + 10 }

        toPos : FCPort -> FCNode -> Vector2
        toPos fcPort fcNode =
            addRelativePosition fcNode.position fcPort.position fcNode.dim

        getPort : FCNode -> Maybe FCPort
        getPort fcNode =
            List.head (List.filter (.id >> (==) portId) fcNode.ports)
    in
    Maybe.map2 toPos (Maybe.andThen getPort node) node


updatePosition : Vector2 -> Vector2 -> Vector2
updatePosition oldPos deltaPos =
    { x = oldPos.x + deltaPos.x, y = oldPos.y + deltaPos.y }


generatePath : Vector2 -> Vector2 -> String
generatePath startPos endPos =
    let
        positionToString pos =
            String.fromFloat pos.x ++ "," ++ String.fromFloat pos.y

        width =
            abs (startPos.x - endPos.x)

        curve =
            Vector2 (width * 1.5) 0
    in
    "M"
        ++ positionToString startPos
        ++ " C "
        ++ positionToString (MathUtils.addVector2 startPos curve)
        ++ " "
        ++ positionToString (MathUtils.subVector2 endPos curve)
        ++ " "
        ++ positionToString endPos
