module Main exposing (..)

import ExampleViewer exposing (Model, Action)
import RouteHash
import RouteUrl exposing (WrappedModel, WrappedMsg)


main : Program Never (WrappedModel Model) (WrappedMsg Action)
main =
    RouteHash.program
        { prefix = RouteHash.defaultPrefix
        , delta2update = ExampleViewer.delta2update
        , location2action = ExampleViewer.location2action
        , init = ExampleViewer.init
        , update = ExampleViewer.update
        , view = ExampleViewer.view
        , subscriptions = ExampleViewer.subscriptions
        }
