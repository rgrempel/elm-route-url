module Example2.Counter exposing
    ( Action
    , Model
    , delta2fragment
    , fragment2messages
    , init
    , update
    , view
    )

import Html exposing (..)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import String exposing (toInt)



-- MODEL


type alias Model =
    Int


init : Int -> Model
init count =
    count



-- UPDATE


{-| We add a Set action for the advanced example, so that we
can restore a particular bookmarked state.
-}
type Action
    = Increment
    | Decrement
    | Set Int


update : Action -> Model -> Model
update action model =
    case action of
        Increment ->
            model + 1

        Decrement ->
            model - 1

        Set value ->
            value



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



-- Routing (New API)


{-| We'll just send back a string
-}
delta2fragment : Model -> Model -> String
delta2fragment previous current =
    String.fromInt current


{-| We'll just take a string
-}
fragment2messages : Maybe String -> List Action
fragment2messages mFragment =
    case mFragment of
        Just fragment ->
            case toInt fragment of
                Just value ->
                    [ Set value ]

                Nothing ->
                    []

        Nothing ->
            []
