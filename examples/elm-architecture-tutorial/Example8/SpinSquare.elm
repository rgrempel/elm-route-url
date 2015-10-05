module Example8.SpinSquare (Model, Action, init, update, view, delta2update, location2action) where

import Easing exposing (ease, easeOutBounce, float)
import Effects exposing (Effects)
import Html exposing (Html)
import Svg exposing (svg, rect, g, text, text')
import Svg.Attributes exposing (..)
import Svg.Events exposing (onClick)
import Time exposing (Time, second)
import RouteHash exposing (HashUpdate)
import String


-- MODEL

type alias Model =
    { angle : Float
    , animationState : AnimationState
    }


type alias AnimationState =
    Maybe { prevClockTime : Time,  elapsedTime: Time }


init : (Model, Effects Action)
init =
  ( { angle = 0, animationState = Nothing }
  , Effects.none
  )


rotateStep = 90
duration = second


-- UPDATE

-- For the advanced example, allow setting the angle directly
type Action
    = Spin
    | Tick Time
    | SetAngle Float


update : Action -> Model -> (Model, Effects Action)
update msg model =
  case msg of
    Spin ->
      case model.animationState of
        Nothing ->
          ( model, Effects.tick Tick )

        Just _ ->
          ( model, Effects.none )

    Tick clockTime ->
      let
        newElapsedTime =
          case model.animationState of
            Nothing ->
              0

            Just {elapsedTime, prevClockTime} ->
              elapsedTime + (clockTime - prevClockTime)
      in
        if newElapsedTime > duration then
          ( { angle = model.angle + rotateStep
            , animationState = Nothing
            }
          , Effects.none
          )
        else
          ( { angle = model.angle
            , animationState = Just { elapsedTime = newElapsedTime, prevClockTime = clockTime }
            }
          , Effects.tick Tick
          )

    SetAngle angle ->
        ( { angle = angle
          , animationState = Nothing
          }
        , Effects.none
        )


-- VIEW

toOffset : AnimationState -> Float
toOffset animationState =
  case animationState of
    Nothing ->
      0

    Just {elapsedTime} ->
      ease easeOutBounce float 0 rotateStep duration elapsedTime


view : Signal.Address Action -> Model -> Html
view address model =
  let
    angle =
      model.angle + toOffset model.animationState
  in
    svg
      [ width "200", height "200", viewBox "0 0 200 200" ]
      [ g [ transform ("translate(100, 100) rotate(" ++ toString angle ++ ")")
          , onClick (Signal.message address Spin)
          ]
          [ rect
              [ x "-50"
              , y "-50"
              , width "100"
              , height "100"
              , rx "15"
              , ry "15"
              , style "fill: #60B5CC;"
              ]
              []
          , text' [ fill "white", textAnchor "middle" ] [ text "Click me!" ]
          ]
      ]


-- Routing

-- Again, we don't necessarily need to use the same signature always ...
delta2update : Model -> Maybe String
delta2update current =
    -- We only want to update if our animation state is Nothing
    if current.animationState == Nothing
        then
            Just <|
                toString current.angle

        else
            Nothing


location2action : String -> Maybe Action
location2action location =
    Maybe.map SetAngle <|
        Result.toMaybe <|
            String.toFloat location
