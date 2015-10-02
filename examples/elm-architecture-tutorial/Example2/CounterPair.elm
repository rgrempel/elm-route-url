module Example2.CounterPair where

import Example2.Counter as Counter
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


-- MODEL

type alias Model =
    { topCounter : Counter.Model
    , bottomCounter : Counter.Model
    }


-- Rewrote to move initialization from Main.elm
init : Model
init =
    { topCounter = Counter.init 0
    , bottomCounter = Counter.init 0
    }


-- UPDATE

type Action
    = Reset
    | Top Counter.Action
    | Bottom Counter.Action


update : Action -> Model -> Model
update action model =
  case action of
    Reset -> init

    Top act ->
      { model |
          topCounter <- Counter.update act model.topCounter
      }

    Bottom act ->
      { model |
          bottomCounter <- Counter.update act model.bottomCounter
      }


-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
  div []
    [ Counter.view (Signal.forwardTo address Top) model.topCounter
    , Counter.view (Signal.forwardTo address Bottom) model.bottomCounter
    , button [ onClick address Reset ] [ text "RESET" ]
    ]


-- We add a separate function to get a title, which the ExampleViewer uses to
-- construct a table of contents. Sometimes, you might have a function of this
-- kind return `Html` instead, depending on where it makes sense to do some of
-- the construction.
title : String
title = "Pair of Counters"
