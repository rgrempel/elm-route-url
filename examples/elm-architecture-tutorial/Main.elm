import Effects exposing (Never)
import ExampleViewer exposing (Model, Action(NoOp), init, update, view)
import StartApp exposing (App)
import Task exposing (Task)
import Html exposing (Html) 
import RouteHash


app : App Model
app =
    StartApp.start
        { init = init
        , update = update
        , view = view
        , inputs = [ messages.signal ]
        }


messages : Signal.Mailbox Action
messages =
    Signal.mailbox NoOp


main : Signal Html
main =
    app.html


port tasks : Signal (Task Never ())
port tasks =
    app.tasks


port routeTasks : Signal (Task () ())
port routeTasks =
    RouteHash.start
        { prefix = RouteHash.defaultPrefix
        , address = messages.address
        , models = app.model
        , delta2update = ExampleViewer.delta2update
        , location2action = ExampleViewer.location2action
        }
