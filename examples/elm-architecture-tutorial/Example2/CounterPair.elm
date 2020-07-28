module Example2.CounterPair exposing (..)

import Example2.Counter as Counter
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import RouteUrl exposing (HistoryEntry(..), UrlChange(..))
import Url exposing (Url)
import Url.Builder exposing (relative, string)
import Url.Parser exposing (parse, query)
import Url.Parser.Query exposing (map2)



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



-- Routing (New API)


{-| We'll put the two counters in the query parameters, just for fun
-}
delta2builder : Model -> Model -> Maybe UrlChange
delta2builder previous current =
    Just <|
        NewQuery NewEntry <|
            { query =
                -- work around https://github.com/elm/url/issues/37
                String.dropLeft 1 <|
                    relative []
                        [ string "top" (Counter.delta2fragment previous.topCounter current.topCounter)
                        , string "bottom" (Counter.delta2fragment previous.bottomCounter current.bottomCounter)
                        ]
            , fragment = Nothing
            }


builder2messages : Url -> List Action
builder2messages url =
    let
        workaroundUrl =
            -- https://github.com/elm/url/issues/17
            { url | path = "" }

        parseQuery =
            query <|
                map2 List.append
                    (Url.Parser.Query.map (List.map Top << Counter.fragment2messages) <| Url.Parser.Query.string "top")
                    (Url.Parser.Query.map (List.map Bottom << Counter.fragment2messages) <| Url.Parser.Query.string "bottom")
    in
    case parse parseQuery workaroundUrl of
        Nothing ->
            []

        Just actions ->
            actions
