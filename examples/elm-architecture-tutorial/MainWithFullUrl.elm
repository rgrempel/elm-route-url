module MainWithFullUrl exposing (..)

import ExampleViewer exposing (Action(..), Model)
import RouteUrl exposing (RouteUrlProgram)


main : RouteUrlProgram () Model Action
main =
    RouteUrl.program
        { delta2url = ExampleViewer.delta2url
        , location2messages = ExampleViewer.url2messages
        , init = ExampleViewer.init
        , update = ExampleViewer.update
        , view = ExampleViewer.view
        , subscriptions = ExampleViewer.subscriptions
        , onExternalUrlRequest = ExternalUrlRequested
        }
