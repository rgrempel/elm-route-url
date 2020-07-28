module Example3.Counter exposing (Action, Model, init, update, view)

import Html exposing (..)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)



-- MODEL


type alias Model =
    Int


init : Int -> Model
init count =
    count



-- UPDATE


type Action
    = Increment
    | Decrement


update : Action -> Model -> Model
update action model =
    case action of
        Increment ->
            model + 1

        Decrement ->
            model - 1



-- VIEW


view : Model -> Html Action
view model =
    div []
        [ button [ onClick Decrement ] [ text "-" ]
        , div countStyle [ text (String.fromInt model) ]
        , button [ onClick Increment ] [ text "+" ]
        ]


countStyle : List (Attribute any)
countStyle =
    [ style "font-size" "20px"
    , style "font-family" "monospace"
    , style "display" "inline-block"
    , style "width" "50px"
    , style "text-align" "center"
    ]
