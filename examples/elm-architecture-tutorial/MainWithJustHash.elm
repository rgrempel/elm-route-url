module Main exposing (..)

import ExampleViewer exposing (Model, Action)
import RouteUrl exposing (WrappedModel, WrappedMsg)


main : Program Never (WrappedModel Model) (WrappedMsg Action)
main =
    RouteUrl.program
        { delta2url = ExampleViewer.delta2hash
        , location2messages = ExampleViewer.hash2messages
        , init = ExampleViewer.init
        , update = ExampleViewer.update
        , view = ExampleViewer.view
        , subscriptions = ExampleViewer.subscriptions
        }
