import ExampleViewer
import RouteUrl


main : Program Never
main =
    RouteUrl.program
        { delta2url = ExampleViewer.delta2hash
        , location2messages = ExampleViewer.hash2messages
        , init = ExampleViewer.init
        , update = ExampleViewer.update
        , view = ExampleViewer.view
        , subscriptions = ExampleViewer.subscriptions
        }
