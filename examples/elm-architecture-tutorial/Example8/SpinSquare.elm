module Example8.SpinSquare exposing (Model, Action, init, update, view, delta2update, location2action, subscriptions)

import Ease exposing (outBounce)
import Html exposing (Html)
import Svg exposing (svg, rect, g, text, text_)
import Svg.Attributes exposing (..)
import Svg.Events exposing (onClick)
import Time exposing (Time, second)
import RouteHash exposing (HashUpdate)
import AnimationFrame
import String


-- MODEL


type alias Model =
    { angle : Float
    , animationState : Maybe AnimationState
    }


type alias AnimationState =
    { elapsedTime : Time
    , step : Float
    }


init : ( Model, Cmd Action )
init =
    ( { angle = 0, animationState = Nothing }
    , Cmd.none
    )


rotateStep =
    90


duration =
    second



-- UPDATE


{-| For the advanced example, allow setting the angle directly
-}
type Action
    = Spin
    | Tick Time
    | SetAngle Float


subscriptions : Model -> Sub Action
subscriptions model =
    case model.animationState of
        Just _ ->
            AnimationFrame.diffs Tick

        Nothing ->
            Sub.none


update : Action -> Model -> ( Model, Cmd Action )
update msg model =
    case msg of
        Spin ->
            case model.animationState of
                Nothing ->
                    ( { model
                        | animationState =
                            Just
                                { elapsedTime = 0
                                , step = rotateStep
                                }
                      }
                    , Cmd.none
                    )

                Just _ ->
                    ( model, Cmd.none )

        Tick diff ->
            case model.animationState of
                Nothing ->
                    -- We weren't expecting a tick, so this is just a stray
                    ( model, Cmd.none )

                Just animation ->
                    let
                        newElapsedTime =
                            animation.elapsedTime + diff
                    in
                        if newElapsedTime > duration then
                            -- The animation is finished, so actually update the
                            -- model by changing the angle.
                            ( { angle = model.angle + animation.step
                              , animationState = Nothing
                              }
                            , Cmd.none
                            )
                        else
                            -- We're still animating, so update the time and let
                            -- the view take care of drawing.
                            ( { angle = model.angle
                              , animationState = Just { animation | elapsedTime = newElapsedTime }
                              }
                            , Cmd.none
                            )

        SetAngle angle ->
            ( { model
                | animationState =
                    Just
                        { elapsedTime = 0
                        , step = angle - model.angle
                        }
              }
            , Cmd.none
            )



-- VIEW


toOffset : Maybe AnimationState -> Float
toOffset animationState =
    case animationState of
        Nothing ->
            0

        Just animation ->
            (outBounce (animation.elapsedTime / duration)) * animation.step


view : Model -> Html Action
view model =
    let
        angle =
            model.angle + toOffset model.animationState
    in
        svg
            [ width "200", height "200", viewBox "0 0 200 200" ]
            [ g
                [ transform ("translate(100, 100) rotate(" ++ toString angle ++ ")")
                , onClick Spin
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
                , text_ [ fill "white", textAnchor "middle" ] [ text "Click me!" ]
                ]
            ]



-- Routing


{-| Again, we don't necessarily need to use the same signature always ...
-}
delta2update : Model -> Maybe String
delta2update current =
    -- We only want to update if our animation state is Nothing, since
    -- we don't want to set the history for every animation step
    if current.animationState == Nothing then
        Just <|
            toString current.angle
    else
        Nothing


location2action : String -> Maybe Action
location2action location =
    Maybe.map SetAngle <|
        Result.toMaybe <|
            String.toFloat location
