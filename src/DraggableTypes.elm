module DraggableTypes exposing (DraggableTypes(..))

import FlowChart.Types exposing (..)


type DraggableTypes
    = DCanvas
    | DNode FCNode
    | DPort String FCPort
    | None
