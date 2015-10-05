module Example8.SpinSquarePair where

import Effects exposing (Effects)
import Html exposing (..)
import Html.Attributes exposing (..)
import Example8.SpinSquare as SpinSquare
import RouteHash exposing (HashUpdate)


-- MODEL

type alias Model =
    { left : SpinSquare.Model
    , right : SpinSquare.Model
    }


init : (Model, Effects Action)
init =
  let
    (left, leftFx) = SpinSquare.init
    (right, rightFx) = SpinSquare.init
  in
    ( Model left right
    , Effects.batch
        [ Effects.map Left leftFx
        , Effects.map Right rightFx
        ]
    )


-- UPDATE

type Action
    = Left SpinSquare.Action
    | Right SpinSquare.Action


update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    Left act ->
      let
        (left, fx) = SpinSquare.update act model.left
      in
        ( Model left model.right
        , Effects.map Left fx
        )

    Right act ->
      let
        (right, fx) = SpinSquare.update act model.right
      in
        ( Model model.left right
        , Effects.map Right fx
        )



-- VIEW

(=>) = (,)


view : Signal.Address Action -> Model -> Html
view address model =
  div [ style [ "display" => "flex" ] ]
    [ SpinSquare.view (Signal.forwardTo address Left) model.left
    , SpinSquare.view (Signal.forwardTo address Right) model.right
    ]


-- We add a separate function to get a title, which the ExampleViewer uses to
-- construct a table of contents. Sometimes, you might have a function of this
-- kind return `Html` instead, depending on where it makes sense to do some of
-- the construction. Or, you could track the title in the higher level module,
-- if you prefer that.
title : String
title = "Pair of spinning squares"


-- Routing

delta2update : Model -> Model -> Maybe HashUpdate
delta2update previous current =
    let
        left =
            SpinSquare.delta2update current.left

        right =
            SpinSquare.delta2update current.right

    in
        left `Maybe.andThen` (\l ->
            right `Maybe.andThen` (\r ->
                Just <|
                    RouteHash.set [l, r]
            )
        )


location2action : List String -> List Action
location2action list =
    case list of
        left :: right :: rest ->
            List.filterMap identity
                [ Maybe.map Left <| SpinSquare.location2action left
                , Maybe.map Right <| SpinSquare.location2action right
                ]

        _ ->
            []
