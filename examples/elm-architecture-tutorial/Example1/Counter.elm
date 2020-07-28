module Example1.Counter exposing (..)

import Html exposing (..)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import RouteUrl exposing (HistoryEntry(..), UrlChange(..))
import String exposing (toInt)
import Url exposing (Url)



-- MODEL


type alias Model =
    Int


{-| Added from Main.elm
-}
init : Model
init =
    0



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


{-| We add a separate function to get a title, which the ExampleViewer uses to
construct a table of contents. Sometimes, you might have a function of this
kind return `Html` instead, depending on where it makes sense to do some of
the construction.
-}
title : String
title =
    "Counter"



-- Routing (New API)


delta2builder : Model -> Model -> Maybe UrlChange
delta2builder previous current =
    Just <| NewPath NewEntry <| { path = String.fromInt current, query = Nothing, fragment = Nothing }


builder2messages : (Url -> Maybe String) -> Url -> List Action
builder2messages extractPath url =
    case extractPath url of
        Nothing ->
            []

        Just path ->
            case String.split "/" path of
                first :: rest ->
                    case toInt first of
                        Just value ->
                            [ Set value ]

                        Nothing ->
                            -- If it wasn't an integer, then no action ... we could
                            -- show an error instead, of course.
                            []

                _ ->
                    -- If nothing provided for this part of the URL, return empty list
                    []
