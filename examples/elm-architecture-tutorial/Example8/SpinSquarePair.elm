module Example8.SpinSquarePair exposing (..)

import Example8.SpinSquare as SpinSquare
import Html exposing (..)
import Html.Attributes exposing (..)
import Maybe.Extra
import RouteUrl exposing (HistoryEntry(..), UrlChange(..))
import Url exposing (Url)
import Url.Builder exposing (relative, string)
import Url.Parser exposing (parse, query)
import Url.Parser.Query exposing (map2)



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


view : Model -> Html Action
view model =
    div [ style "display" "flex" ]
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
-- New `RouteUrl` API


delta2builder : Model -> Model -> Maybe UrlChange
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
                            Just <|
                                NewQuery NewEntry
                                    { query =
                                        -- work around https://github.com/elm/url/issues/37
                                        String.dropLeft 1 <|
                                            relative [] [ string "left" l, string "right" r ]
                                    , fragment = Nothing
                                    }
                        )
            )


builder2messages : Url -> List Action
builder2messages url =
    -- Remember that you can parse as you like ... this is just
    -- an example, and there are better ways.
    let
        workaroundUrl =
            -- https://github.com/elm/url/issues/17
            { url | path = "" }

        parseQuery =
            query <|
                map2 List.append
                    (Url.Parser.Query.map (List.map Left << Maybe.Extra.toList << SpinSquare.location2action) <| Url.Parser.Query.string "left")
                    (Url.Parser.Query.map (List.map Right << Maybe.Extra.toList << SpinSquare.location2action) <| Url.Parser.Query.string "right")
    in
    case parse parseQuery workaroundUrl of
        Nothing ->
            []

        Just actions ->
            actions
