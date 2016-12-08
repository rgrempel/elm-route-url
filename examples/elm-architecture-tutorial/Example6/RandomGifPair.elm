module Example6.RandomGifPair exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import RouteHash exposing (HashUpdate)
import RouteUrl.Builder exposing (Builder, path, appendToPath)
import Example6.RandomGif as RandomGif


-- MODEL


type alias Model =
    { left : RandomGif.Model
    , right : RandomGif.Model
    }


{-| Rewrote to move initialization strings from Main.elm
-}
init : ( Model, Cmd Action )
init =
    let
        leftTopic =
            "funny cats"

        rightTopic =
            "funny dogs"

        ( left, leftFx ) =
            RandomGif.init leftTopic

        ( right, rightFx ) =
            RandomGif.init rightTopic
    in
        ( Model left right
        , Cmd.batch
            [ Cmd.map Left leftFx
            , Cmd.map Right rightFx
            ]
        )



-- UPDATE


type Action
    = Left RandomGif.Action
    | Right RandomGif.Action


update : Action -> Model -> ( Model, Cmd Action )
update action model =
    case action of
        Left act ->
            let
                ( left, fx ) =
                    RandomGif.update act model.left
            in
                ( Model left model.right
                , Cmd.map Left fx
                )

        Right act ->
            let
                ( right, fx ) =
                    RandomGif.update act model.right
            in
                ( Model model.left right
                , Cmd.map Right fx
                )



-- VIEW


view : Model -> Html Action
view model =
    div [ style [ ( "display", "flex" ) ] ]
        [ Html.map Left (RandomGif.view model.left)
        , Html.map Right (RandomGif.view model.right)
        ]


{-| We add a separate function to get a title, which the ExampleViewer uses to
construct a table of contents. Sometimes, you might have a function of this
kind return `Html` instead, depending on where it makes sense to do some of
the construction. Or, you could track the title in the higher level module,
if you prefer that.
-}
title : String
title =
    "Pair of Random Gifs"



-- Routing (Old API)


delta2update : Model -> Model -> Maybe HashUpdate
delta2update previous current =
    let
        left =
            Maybe.map RouteHash.extract <|
                RandomGif.delta2update previous.left current.left

        right =
            Maybe.map RouteHash.extract <|
                RandomGif.delta2update previous.right current.right
    in
        -- Essentially, we want to combine left and right. I should think about
        -- how to improve the API for this. We can simplify in this case because
        -- we happen to know that both sides will be lists of length 1. If the
        -- lengths could vary, we'd have to do something more complex.
        left
            |> Maybe.andThen
                (\l ->
                    right
                        |> Maybe.andThen
                            (\r -> Just (l ++ r))
                )
            |> Maybe.map RouteHash.set


location2action : List String -> List Action
location2action list =
    -- This is simplified because we know that each sub-module will supply a
    -- list with one element ... otherwise, we'd have to do something more
    -- complex.
    case list of
        left :: right :: rest ->
            List.concat
                [ List.map Left <| RandomGif.location2action [ left ]
                , List.map Right <| RandomGif.location2action [ right ]
                ]

        _ ->
            []



-- Routing (New API)


delta2builder : Model -> Model -> Maybe Builder
delta2builder previous current =
    let
        left =
            RandomGif.delta2builder previous.left current.left

        right =
            RandomGif.delta2builder previous.right current.right
    in
        -- Essentially, we want to combine left and right.
        left
            |> Maybe.andThen
                (\l ->
                    right
                        |> Maybe.andThen
                            (\r ->
                                Just <| appendToPath (path r) l
                            )
                )


builder2messages : Builder -> List Action
builder2messages builder =
    -- This is simplified because we know that each sub-module will supply a
    -- list with one element ... otherwise, we'd have to do something more
    -- complex.
    case path builder of
        left :: right :: rest ->
            List.concat
                [ List.map Left <| RandomGif.location2action [ left ]
                , List.map Right <| RandomGif.location2action [ right ]
                ]

        _ ->
            []
