module EventListenerExample exposing (Model, Msg(..), init, main, update, view)

import Browser
import FlowChart
import FlowChart.Events as FCEvents
import FlowChart.Types as FCTypes
import Html exposing (..)
import Html.Attributes as A
import Html.Events


main : Program () Model Msg
main =
    Browser.element { init = init, view = view, update = update, subscriptions = subscriptions }


type alias Model =
    { fcModel : FlowChart.Model Msg
    , clickedNodeId : Maybe String
    }


type Msg
    = CanvasMsg FlowChart.Msg
    | CanvasClick
    | NodeClick FCTypes.FCNode
    | LinkClick FCTypes.FCLink


flowChartEvent : FlowChart.FCEventConfig Msg
flowChartEvent =
    FlowChart.initEventConfig
        [ FCEvents.onCanvasClick CanvasClick
        , FCEvents.onNodeClick NodeClick
        , FCEvents.onLinkClick LinkClick
        ]


init : () -> ( Model, Cmd Msg )
init _ =
    ( { fcModel =
            FlowChart.init
                { nodes =
                    [ createNode "node-0" (FCTypes.Vector2 10 10)
                    , createNode "node-1" (FCTypes.Vector2 100 200)
                    ]
                , position = FCTypes.Vector2 0 0
                , links = []
                , portConfig = FlowChart.defaultPortConfig
                , linkConfig = FlowChart.defaultLinkConfig
                }
                CanvasMsg
      , clickedNodeId = Nothing
      }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    FlowChart.subscriptions model


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CanvasMsg cMsg ->
            FlowChart.update flowChartEvent cMsg model

        CanvasClick ->
            ( { model | clickedNodeId = Nothing }, Cmd.none )

        NodeClick fcNode ->
            ( { model | clickedNodeId = Just fcNode.id }, Cmd.none )

        LinkClick fcLink ->
            let
                _ =
                    Debug.log "key" fcLink
            in
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    div []
        [ p [] [ text "Click on any Node to change color. Click on canvas to revert" ]
        , FlowChart.view model
            nodeToHtml
            [ A.style "height" "500px"
            , A.style "width" "85%"
            , A.style "background-color" "lightgrey"
            ]
        ]


nodeToHtml : FCTypes.FCNode -> Model -> Html FlowChart.Msg
nodeToHtml fcNode model =
    let
        bgColor =
            if model.clickedNodeId == Just fcNode.id then
                "#81ceca"

            else
                "white"
    in
    div
        [ A.style "width" "100%"
        , A.style "height" "100%"
        , A.style "background-color" bgColor
        ]
        [ text fcNode.id ]



-- HELPER FUNCTIONS


createNode : String -> FCTypes.Vector2 -> FCTypes.FCNode
createNode id position =
    { position = position
    , id = id
    , dim = FCTypes.Vector2 130 100
    , nodeType = "default"
    , ports =
        [ { id = "port-" ++ id ++ "-0", position = FCTypes.Vector2 0 0.42 }
        , { id = "port-" ++ id ++ "-1", position = FCTypes.Vector2 0.85 0.42 }
        ]
    }
