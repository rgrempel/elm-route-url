module Example6.RandomGifPair exposing (..)

import Example6.RandomGif as RandomGif
import Html exposing (..)
import Html.Attributes exposing (..)
import RouteUrl exposing (HistoryEntry(..), UrlChange(..))
import Url exposing (Url)



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
    div [ style "display" "flex" ]
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



-- Routing (New API)


delta2builder : Model -> Model -> Maybe UrlChange
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
                            Just <| NewPath NewEntry { path = l ++ "/" ++ r, query = Nothing, fragment = Nothing }
                        )
            )


builder2messages : (Url -> Maybe String) -> Url -> List Action
builder2messages extractPath url =
    case extractPath url of
        Nothing ->
            []

        Just path ->
            case String.split "/" path of
                left :: right :: rest ->
                    List.concat
                        [ List.map Left <| RandomGif.location2action [ left ]
                        , List.map Right <| RandomGif.location2action [ right ]
                        ]

                _ ->
                    []
