module Example4.Counter exposing (Action, Context, Model, init, update, view, viewWithRemoveButton)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)



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


type alias Context super =
    { modify : Action -> super
    , remove : super
    }


viewWithRemoveButton : Context super -> Model -> Html super
viewWithRemoveButton context model =
    div []
        [ Html.map context.modify (button [ onClick Decrement ] [ text "-" ])
        , div countStyle [ text (String.fromInt model) ]
        , Html.map context.modify (button [ onClick Increment ] [ text "+" ])
        , div countStyle []
        , button [ onClick context.remove ] [ text "X" ]
        ]


countStyle : List (Attribute any)
countStyle =
        [ style "font-size" "20px"
        , style "font-family" "monospace"
        , style "display" "inline-block"
        , style "width" "50px"
        , style "text-align" "center"
        ]
