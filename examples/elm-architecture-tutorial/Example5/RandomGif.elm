module Example5.RandomGif exposing (..)

import Html exposing (..)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Http exposing (expectJson)
import Json.Decode as Json
import RouteUrl exposing (HistoryEntry(..), UrlChange(..))
import Task
import Url exposing (Url)



-- MODEL


{-| For the advanced example, we need to keep track of a status in order to deal
with the fact that a request for a random gif may be in progress when our
location changes. In that case, we want (in effect) to cancel the request.
-}
type alias Model =
    { topic : String
    , gifUrl : String
    , requestStatus : RequestStatus
    }


{-| Tracks whether we should use or ignore the response from getRandomGif
-}
type RequestStatus
    = Use
    | Ignore


{-| Rewrote to move initialization from Main.elm.

We start the requestStatus as Use so that we will use the response to the
initial request we issue here.

-}
init : ( Model, Cmd Action )
init =
    ( Model "funny cats" "assets/waiting.gif" Use
    , getRandomGif "funny cats"
    )



-- UPDATE


{-| We end up needing a separate action for setting the gif from the location,
because in that case we also need to "cancel" any outstanding requests for a
random gif.
-}
type Action
    = RequestMore
    | NewGif (Result Http.Error String)
    | NewGifFromLocation String


update : Action -> Model -> ( Model, Cmd Action )
update action model =
    case action of
        RequestMore ->
            -- When we're explicitly asked to get a random gif, then mark that
            -- we should use the response.
            ( { model | requestStatus = Use }
            , getRandomGif model.topic
            )

        NewGif (Ok url) ->
            case model.requestStatus of
                Use ->
                    ( { model | gifUrl = url }
                    , Cmd.none
                    )

                -- This will be set to ignore if our location has changed since
                -- the request was issued. In that case, we want to ignore the
                -- result of the randomGif request (which was, of course, async)
                Ignore ->
                    ( model, Cmd.none )

        NewGif (Err _) ->
            -- Should really show the error ... do nothing for now.
            ( model, Cmd.none )

        NewGifFromLocation url ->
            -- When we get the gif from the URL, then ignore any randomGif requests
            -- that haven't resolved yet.
            ( { model
                | gifUrl = url
                , requestStatus = Ignore
              }
            , Cmd.none
            )



-- VIEW


view : Model -> Html Action
view model =
    div [ style "width" "200px" ]
        [ h2 headerStyle [ text model.topic ]
        , div (imgStyle model.gifUrl) []
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
        [ ( "api_key", "dc6zaTOxFJmzC" )
        , ( "tag", topic )
        ]


decodeUrl : Json.Decoder String
decodeUrl =
    Json.at [ "data", "image_url" ] Json.string


{-| We add a separate function to get a title, which the ExampleViewer uses to
construct a table of contents. Sometimes, you might have a function of this
kind return `Html` instead, depending on where it makes sense to do some of
the construction. Or, you could track the title in the higher level module,
if you prefer that.
-}
title : String
title =
    "Random Gif"



-- Routing (New API)


delta2builder : Model -> Model -> Maybe UrlChange
delta2builder previous current =
    if current.gifUrl == (Tuple.first init).gifUrl then
        -- If we're waiting for the first random gif, don't generate an entry ...
        -- wait for the gif to arrive.
        Nothing

    else
        NewPath NewEntry
            { path = current.gifUrl, query = Nothing, fragment = Nothing }
            |> Just


builder2messages : (Url -> Maybe String) -> Url -> List Action
builder2messages extractPath url =
    case extractPath url of
        Nothing ->
            []

        Just path ->
            case String.split "/" path of
                -- If we have a gifUrl, then use it
                gifUrl :: rest ->
                    [ NewGifFromLocation gifUrl ]

                -- Otherwise, do nothing
                _ ->
                    []
