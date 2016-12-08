module Example2.CounterPair exposing (..)

import Example2.Counter as Counter
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import RouteHash exposing (HashUpdate)
import RouteUrl.Builder exposing (Builder, builder, insertQuery, getQuery)


-- MODEL


type alias Model =
    { topCounter : Counter.Model
    , bottomCounter : Counter.Model
    }


{-| Rewrote to move initialization from Main.elm
-}
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
        Reset ->
            init

        Top act ->
            { model
                | topCounter = Counter.update act model.topCounter
            }

        Bottom act ->
            { model
                | bottomCounter = Counter.update act model.bottomCounter
            }



-- VIEW


view : Model -> Html Action
view model =
    div []
        [ Html.map Top (Counter.view model.topCounter)
        , Html.map Bottom (Counter.view model.bottomCounter)
        , button [ onClick Reset ] [ text "RESET" ]
        ]


{-| We add a separate function to get a title, which the ExampleViewer uses to
construct a table of contents. Sometimes, you might have a function of this
kind return `Html` instead, depending on where it makes sense to do some of
the construction.
-}
title : String
title =
    "Pair of Counters"



-- Routing (Old API)


{-| To encode state in the URL, we'll just delegate & concatenate
This will produce partial URLs like /6/7
-}
delta2update : Model -> Model -> Maybe HashUpdate
delta2update previous current =
    -- The implementation is not especially elegant ... perhaps
    -- we need a few more HashUpdate helpers, to help combining them?
    [ Counter.delta2update previous.topCounter current.topCounter
    , Counter.delta2update previous.bottomCounter current.bottomCounter
    ]
        |> List.map (Maybe.withDefault [] << Maybe.map RouteHash.extract)
        |> List.concat
        |> RouteHash.set
        |> Just


location2action : List String -> List Action
location2action list =
    case list of
        -- We're expecting two things that we can delegate down ...
        top :: bottom :: rest ->
            List.concat
                [ List.map Top <| Counter.location2action [ top ]
                , List.map Bottom <| Counter.location2action [ bottom ]
                ]

        -- If we don't have what we expect, then no actions
        _ ->
            []



-- Routing (New API)


{-| We'll put the two counters in the query parameters, just for fun
-}
delta2builder : Model -> Model -> Maybe Builder
delta2builder previous current =
    builder
        |> insertQuery "top" (Counter.delta2fragment previous.topCounter current.topCounter)
        |> insertQuery "bottom" (Counter.delta2fragment previous.bottomCounter current.bottomCounter)
        |> Just


builder2messages : Builder -> List Action
builder2messages builder =
    let
        left =
            getQuery "top" builder
                |> Maybe.map ((List.map Top) << Counter.fragment2messages)

        right =
            getQuery "bottom" builder
                |> Maybe.map ((List.map Bottom) << Counter.fragment2messages)
    in
        [ left, right ]
            |> List.filterMap identity
            |> List.concat
