import Effects exposing (Never)
import ExampleViewer exposing (Model, init, update, view)
import StartApp exposing (App)
import Task exposing (Task)
import Html exposing (Html) 


app : App Model 
app =
    StartApp.start
        { init = init
        , update = update
        , view = view
        , inputs = []
        }


main : Signal Html
main =
    app.html


port tasks : Signal (Task Never ())
port tasks =
    app.tasks
