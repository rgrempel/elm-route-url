module Example8.SpinSquarePair exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Example8.SpinSquare as SpinSquare
import RouteHash exposing (HashUpdate)
import RouteUrl.Builder as Builder exposing (Builder, builder, insertQuery, getQuery)


-- MODEL


type alias Model =
    { left : SpinSquare.Model
    , right : SpinSquare.Model
    }


init : ( Model, Cmd Action )
init =
    let
        ( left, leftFx ) =
            SpinSquare.init

        ( right, rightFx ) =
            SpinSquare.init
    in
        ( Model left right
        , Cmd.batch
            [ Cmd.map Left leftFx
            , Cmd.map Right rightFx
            ]
        )



-- UPDATE


type Action
    = Left SpinSquare.Action
    | Right SpinSquare.Action


subscriptions : Model -> Sub Action
subscriptions model =
    Sub.batch
        [ Sub.map Left (SpinSquare.subscriptions model.left)
        , Sub.map Right (SpinSquare.subscriptions model.right)
        ]


update : Action -> Model -> ( Model, Cmd Action )
update action model =
    case action of
        Left act ->
            let
                ( left, fx ) =
                    SpinSquare.update act model.left
            in
                ( Model left model.right
                , Cmd.map Left fx
                )

        Right act ->
            let
                ( right, fx ) =
                    SpinSquare.update act model.right
            in
                ( Model model.left right
                , Cmd.map Right fx
                )



-- VIEW


(=>) =
    (,)


view : Model -> Html Action
view model =
    div [ style [ "display" => "flex" ] ]
        [ Html.map Left (SpinSquare.view model.left)
        , Html.map Right (SpinSquare.view model.right)
        ]


{-| We add a separate function to get a title, which the ExampleViewer uses to
construct a table of contents. Sometimes, you might have a function of this
kind return `Html` instead, depending on where it makes sense to do some of
the construction. Or, you could track the title in the higher level module,
if you prefer that.
-}
title : String
title =
    "Pair of spinning squares"



-- Routing
-- Old `RouteHash` API


delta2update : Model -> Model -> Maybe HashUpdate
delta2update previous current =
    let
        left =
            SpinSquare.delta2update current.left

        right =
            SpinSquare.delta2update current.right
    in
        left
            |> Maybe.andThen
                (\l ->
                    right
                        |> Maybe.andThen
                            (\r ->
                                Just <|
                                    RouteHash.set [ l, r ]
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



-- New `RouteUrl` API


delta2builder : Model -> Model -> Maybe Builder
delta2builder previous current =
    let
        left : Maybe String
        left =
            SpinSquare.delta2update current.left

        right : Maybe String
        right =
            SpinSquare.delta2update current.right
    in
        left
            |> Maybe.andThen
                (\l ->
                    right
                        |> Maybe.andThen
                            (\r ->
                                -- Since we can, why not use the query parameters?
                                Just
                                    (builder
                                        |> insertQuery "left" l
                                        |> insertQuery "right" r
                                    )
                            )
                )


builder2messages : Builder -> List Action
builder2messages builder =
    -- Remember that you can parse as you like ... this is just
    -- an example, and there are better ways.
    let
        left =
            getQuery "left" builder

        right =
            getQuery "right" builder
    in
        case ( left, right ) of
            ( Just l, Just r ) ->
                List.filterMap identity
                    [ Maybe.map Left <| SpinSquare.location2action l
                    , Maybe.map Right <| SpinSquare.location2action r
                    ]

            _ ->
                []
