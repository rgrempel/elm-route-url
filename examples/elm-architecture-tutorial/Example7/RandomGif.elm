module Example7.RandomGif exposing (..)

import Html exposing (..)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Http exposing (expectJson)
import Json.Decode as Json
import Task
import Url



-- MODEL


{-| In the advanced example, it's easier to track the gifUrl as a Maybe String
and apply the default value later, since the default value is really a
question for the view, rather than the model.
-}
type alias Model =
    { topic : String
    , gifUrl : Maybe String
    }


{-| We provide for initializing with the gifUrl already set, since that is how
the routing will do it. If the gifUrl is provided, then we skip getting a
random one.
-}
init : String -> Maybe String -> ( Model, Cmd Action )
init topic gifUrl =
    ( Model topic gifUrl
    , if gifUrl == Nothing then
        getRandomGif topic

      else
        Cmd.none
    )



-- UPDATE


type Action
    = RequestMore
    | NewGif (Result Http.Error String)


update : Action -> Model -> ( Model, Cmd Action )
update action model =
    case action of
        RequestMore ->
            ( model, getRandomGif model.topic )

        NewGif (Ok url) ->
            ( Model model.topic (Just url)
            , Cmd.none
            )

        NewGif (Err _) ->
            -- Should really show the error ... do nothing for now.
            ( model, Cmd.none )



-- VIEW


view : Model -> Html Action
view model =
    div [ style "width" "200px" ]
        [ h2 headerStyle [ text model.topic ]
        , div ( imgStyle (Maybe.withDefault "assets/waiting.gif" model.gifUrl) ) []
        , button [ onClick RequestMore ] [ text "More Please!" ]
        ]


headerStyle : List (Attribute any)
headerStyle =
        [ style "width" "200px"
        , style "text-align" "center"
        ]


imgStyle : String -> List (Attribute any)
imgStyle url =
        [ style "display" "inline-block"
        , style "width" "200px"
        , style "height" "200px"
        , style "background-position" "center center"
        , style "background-size" "cover"
        , style "background-image" ("url('" ++ url ++ "')")
        ]



-- EFFECTS


urlWithArgs : String -> List ( String, String ) -> String
urlWithArgs baseUrl args =
    case args of
        [] ->
            baseUrl

        _ ->
            baseUrl ++ "?" ++ String.join "&" (List.map queryPair args)


queryPair : ( String, String ) -> String
queryPair ( key, value ) =
    queryEscape key ++ "=" ++ queryEscape value


queryEscape : String -> String
queryEscape string =
    String.join "+" (String.split "%20" (Url.percentEncode string))


getRandomGif : String -> Cmd Action
getRandomGif topic =
        Http.get { url = randomUrl topic, expect = expectJson NewGif decodeUrl }


randomUrl : String -> String
randomUrl topic =
    urlWithArgs "http://api.giphy.com/v1/gifs/random"
        [ ("api_key", "dc6zaTOxFJmzC")
        , ("tag", topic)
        ]


decodeUrl : Json.Decoder String
decodeUrl =
    Json.at [ "data", "image_url" ] Json.string



-- Routing


{-| Instead of using the same signature all the way down, we'll simplify this
case a little.
-}
encodeLocation : Model -> Maybe (List String)
encodeLocation model =
    -- Don't encode if there's no gifUrl
    if model.gifUrl == Nothing then
        Nothing

    else
        Just
            [ model.topic
            , Maybe.withDefault "" model.gifUrl
            ]
