module ExampleViewer exposing (..)

-- Note that I'm renaming these locally for simplicity.

import Browser exposing (Document, UrlRequest)
import Browser.Navigation exposing (Key)
import Example1.Counter as Example1
import Example2.CounterPair as Example2
import Example3.CounterList as Example3
import Example4.CounterList as Example4
import Example5.RandomGif as Example5
import Example6.RandomGifPair as Example6
import Example7.RandomGifList as Example7
import Example8.SpinSquarePair as Example8
import Html exposing (Html, div, map, p, table, td, text, tr)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import RouteUrl exposing (HistoryEntry, UrlChange(..))
import Url exposing (Url)



-- MODEL


{-| We'll need to know which example we're showing at the moment.
-}
type Example
    = Example1
    | Example2
    | Example3
    | Example4
    | Example5
    | Example6
    | Example7
    | Example8


{-| We need to collect all the data that each example wants to track. Now, we
could do this in a couple of ways. If we want to remember all the data as we
display one thing or another, we would do this as a record. If we wanted to
only remember the data that we're currently looking at, we might do this as
a union type. I'll do it the record way for now.

In a real app, you are likely to divide the model into parts which are
"permanent" (in the sense that the app needs to remember them, no matter
what the user is looking at now), and parts that are "transient" (which need
to be remembered, but only while the user is looking at a particular thing).
So, in that cae, some things would be in a record, whereas other things would
be in a union type.

-}
type alias Model =
    { example1 : Example1.Model
    , example2 : Example2.Model
    , example3 : Example3.Model
    , example4 : Example4.Model
    , example5 : Example5.Model
    , example6 : Example6.Model
    , example7 : Example7.Model
    , example8 : Example8.Model

    -- And, we need to track which example we're actually showing
    , currentExample : Example

    -- And as discussed in the documentation for UrlChange, we need to track the original path
    , originalPath : Maybe (List String)
    }


{-| Now, to init our model, we have to collect each examples init
-}
init : () -> Key -> ( Model, Cmd Action )
init _ _ =
    let
        model =
            { example1 = Example1.init
            , example2 = Example2.init
            , example3 = Example3.init
            , example4 = Example4.init
            , example5 = Tuple.first Example5.init
            , example6 = Tuple.first Example6.init
            , example7 = Tuple.first Example7.init
            , example8 = Tuple.first Example8.init
            , currentExample = Example1
            , originalPath = Nothing
            }

        effects =
            Cmd.batch
                -- We happen to know that examples 1 through 4
                -- have no effects defined.
                [ Cmd.map Example5Action <| Tuple.second Example5.init
                , Cmd.map Example6Action <| Tuple.second Example6.init
                , Cmd.map Example7Action <| Tuple.second Example7.init
                , Cmd.map Example8Action <| Tuple.second Example8.init
                ]
    in
    ( model, effects )



-- SUBSCRIPTIONS


{-| I happen to know that only Example8 uses them
-}
subscriptions : Model -> Sub Action
subscriptions model =
    Sub.map Example8Action (Example8.subscriptions model.example8)



-- UPDATE


type Action
    = SetOriginalPath (List String)
    | Example1Action Example1.Action
    | Example2Action Example2.Action
    | Example3Action Example3.Action
    | Example4Action Example4.Action
    | Example5Action Example5.Action
    | Example6Action Example6.Action
    | Example7Action Example7.Action
    | Example8Action Example8.Action
    | ShowExample Example
    | ExternalUrlRequested String
    | NoOp


update : Action -> Model -> ( Model, Cmd Action )
update action model =
    case action of
        NoOp ->
            ( model, Cmd.none )

        SetOriginalPath paths ->
            ( { model | originalPath = Just paths }, Cmd.none )

        ShowExample example ->
            ( { model | currentExample = example }
            , Cmd.none
            )

        Example1Action subaction ->
            ( { model | example1 = Example1.update subaction model.example1 }
            , Cmd.none
            )

        Example2Action subaction ->
            ( { model | example2 = Example2.update subaction model.example2 }
            , Cmd.none
            )

        Example3Action subaction ->
            ( { model | example3 = Example3.update subaction model.example3 }
            , Cmd.none
            )

        Example4Action subaction ->
            ( { model | example4 = Example4.update subaction model.example4 }
            , Cmd.none
            )

        Example5Action subaction ->
            let
                result =
                    Example5.update subaction model.example5
            in
            ( { model | example5 = Tuple.first result }
            , Cmd.map Example5Action <| Tuple.second result
            )

        Example6Action subaction ->
            let
                result =
                    Example6.update subaction model.example6
            in
            ( { model | example6 = Tuple.first result }
            , Cmd.map Example6Action <| Tuple.second result
            )

        Example7Action subaction ->
            let
                result =
                    Example7.update subaction model.example7
            in
            ( { model | example7 = Tuple.first result }
            , Cmd.map Example7Action <| Tuple.second result
            )

        Example8Action subaction ->
            let
                result =
                    Example8.update subaction model.example8
            in
            ( { model | example8 = Tuple.first result }
            , Cmd.map Example8Action <| Tuple.second result
            )

        ExternalUrlRequested _ ->
            --none of the anchors we produce in our `view` function are external,
            --so we can ignore this
            ( model, Cmd.none )



-- VIEW


view : Model -> Document Action
view model =
    { title = "Example", body = [ viewImpl model ] }


viewImpl : Model -> Html Action
viewImpl model =
    let
        viewExample =
            case model.currentExample of
                Example1 ->
                    map Example1Action (Example1.view model.example1)

                Example2 ->
                    map Example2Action (Example2.view model.example2)

                Example3 ->
                    map Example3Action (Example3.view model.example3)

                Example4 ->
                    map Example4Action (Example4.view model.example4)

                Example5 ->
                    map Example5Action (Example5.view model.example5)

                Example6 ->
                    map Example6Action (Example6.view model.example6)

                Example7 ->
                    map Example7Action (Example7.view model.example7)

                Example8 ->
                    map Example8Action (Example8.view model.example8)

        makeTitle ( index, example, title ) =
            let
                styleList =
                    if example == model.currentExample then
                        [ style "font-weight" "bold"
                        ]

                    else
                        [ style "font-weight" "normal"
                        , style "color" "blue"
                        , style "cursor" "pointer"
                        ]

                -- Note that we compose the full title out of some information the
                -- super-module knows about (the index) and some information the
                -- sub-module knows about (the title)
                fullTitle =
                    text <|
                        "Example "
                            ++ String.fromInt index
                            ++ ": "
                            ++ title

                -- If we're already on a page, we don't have a click action
                clickAction =
                    if example == model.currentExample then
                        []

                    else
                        [ onClick (ShowExample example) ]
            in
            p (styleList ++ clickAction)
                [ fullTitle ]

        toc =
            div [] <|
                List.map makeTitle
                    [ ( 1, Example1, Example1.title )
                    , ( 2, Example2, Example2.title )
                    , ( 3, Example3, Example3.title )
                    , ( 4, Example4, Example4.title )
                    , ( 5, Example5, Example5.title )
                    , ( 6, Example6, Example6.title )
                    , ( 7, Example7, Example7.title )
                    , ( 8, Example8, Example8.title )
                    ]
    in
    table []
        [ tr []
            [ td
                [ style "vertical-align" "top"
                , style "width" "25%"
                , style "padding" "8px"
                , style "margin" "8px"
                ]
                [ toc ]
            , td
                [ style "vertical-align" "top"
                , style "width" "75%"
                , style "padding" "8px"
                , style "margin" "8px"
                , style "border" "1px dotted black"
                ]
                [ viewExample ]
            ]
        ]



-- ROUTING
--


{-| This is an example of the API, if using the whole URL
-}
delta2url : Model -> Model -> Maybe UrlChange
delta2url previous current =
    -- You can construct a `UrlChange` however you like.
    delta2builder identity previous current


{-| An example of the API, if just using the hash
-}
delta2hash : Model -> Model -> Maybe UrlChange
delta2hash previous current =
    -- TODO Here, we're re-using the Path-oriented code, but stuffing everything
    -- into the hash (rather than actually using the full URL).
    let
        movePathToFragment urlChange =
            case urlChange of
                NewPath historyEntry origNewPath ->
                    let
                        fragment =
                            Just origNewPath.path
                    in
                    NewPath historyEntry { origNewPath | path = "", fragment = fragment }

                NewQuery _ _ ->
                    urlChange

                NewFragment _ _ ->
                    urlChange
    in
    delta2builder movePathToFragment previous current


{-| This is the common code that we rely on above.
-}
delta2builder : (UrlChange -> UrlChange) -> Model -> Model -> Maybe UrlChange
delta2builder mungePath previous current =
    let
        submoduleChange =
            case current.currentExample of
                Example1 ->
                    -- First, we ask the submodule for a `Maybe UrlChange`. Then, we use
                    -- `map` to prepend something to the path.
                    Example1.delta2builder previous.example1 current.example1
                        |> Maybe.map (prependToPath [ "example-1" ])
                        |> Maybe.map mungePath

                Example2 ->
                    Example2.delta2builder previous.example2 current.example2
                        |> Maybe.map (prependToPath [ "example-2" ])
                        |> Maybe.map mungePath

                Example3 ->
                    Example3.delta2builder previous.example3 current.example3
                        |> Maybe.map (prependToPath [ "example-3" ])
                        |> Maybe.map mungePath

                Example4 ->
                    Example4.delta2builder previous.example4 current.example4
                        |> Maybe.map (prependToPath [ "example-4" ])
                        |> Maybe.map mungePath

                Example5 ->
                    Example5.delta2builder previous.example5 current.example5
                        |> Maybe.map (prependToPath [ "example-5" ])
                        |> Maybe.map mungePath

                Example6 ->
                    Example6.delta2builder previous.example6 current.example6
                        |> Maybe.map (prependToPath [ "example-6" ])
                        |> Maybe.map mungePath

                Example7 ->
                    Example7.delta2builder previous.example7 current.example7
                        |> Maybe.map (prependToPath [ "example-7" ])
                        |> Maybe.map mungePath

                Example8 ->
                    Example8.delta2builder previous.example8 current.example8
                        |> Maybe.map (prependToPath [ "example-8" ])
                        |> Maybe.map mungePath

        originalPath =
            Maybe.withDefault [] current.originalPath
    in
    Maybe.map (prependToPathImpl "/" originalPath) submoduleChange


prependToPath : List String -> UrlChange -> UrlChange
prependToPath =
    prependToPathImpl ""


prependToPathImpl : String -> List String -> UrlChange -> UrlChange
prependToPathImpl prefix path u =
    let
        pathStr =
            String.concat <| List.intersperse "/" path
    in
    case u of
        NewPath entry pData ->
            let
                newPath =
                    case pData.path of
                        "" ->
                            pathStr

                        _ ->
                            pathStr ++ "/" ++ pData.path
            in
            NewPath entry { pData | path = prefix ++ newPath }

        NewQuery entry qData ->
            NewPath entry { path = prefix ++ pathStr, query = Just qData.query, fragment = qData.fragment }

        NewFragment entry fragment ->
            NewPath entry { path = prefix ++ pathStr, query = Nothing, fragment = Just fragment }


{-| This is an example of a `location2messages` function ... I'm calling it
`url2messages` to illustrate something that uses the full URL.
-}
url2messages : Url -> List Action
url2messages location =
    -- You can parse the `Url` in whatever way you want. There are links to a number of proper parsing packages
    -- in the README.
    builder2messages Nothing (Just << .path) (\url -> \path -> { url | path = path }) location


{-| This is an example of a `location2messages` function ... I'm calling it
`hash2messages` to illustrate something that uses just the hash.
-}
hash2messages : Url -> List Action
hash2messages location =
    -- You can parse the `Url` in whatever way you want. There are links to a number of proper parsing packages
    -- in the README.
    let
        hashMessages =
            builder2messages Nothing .fragment (\url -> \path -> { url | fragment = Just path }) location

        isSetOriginalPath msg =
            case msg of
                SetOriginalPath _ ->
                    True

                _ ->
                    False

        pathMessages =
            url2messages location
                |> List.filter isSetOriginalPath
    in
    pathMessages ++ hashMessages


{-| A `location2messages` function that lets the caller determine how to store the location in the `Url`
-}
builder2messages : Maybe (List String) -> (Url -> Maybe String) -> (Url -> String -> Url) -> Url -> List Action
builder2messages originalPathSegments extractPath insertPath url =
    -- You can parse the `Location` in whatever way you want ... there are a
    -- number of parsing packages listed in the README.
    case extractPath url of
        Nothing ->
            []

        Just path ->
            let
                noMore =
                    case originalPathSegments of
                        Nothing ->
                            -- When loading the example initially, start with example 1
                            [ ShowExample Example1 ]

                        Just segments ->
                            [ SetOriginalPath segments ]
            in
            case String.split "/" path of
                "" :: [] ->
                    noMore

                first :: rest ->
                    let
                        subUrl =
                            insertPath url <| String.concat <| List.intersperse "/" rest
                    in
                    case first of
                        "example-1" ->
                            -- We give the Example1 module a chance to interpret
                            -- the rest of the location, and then we prepend an
                            -- action for the part we interpreted.
                            ShowExample Example1 :: List.map Example1Action (Example1.builder2messages extractPath subUrl)

                        "example-2" ->
                            ShowExample Example2 :: List.map Example2Action (Example2.builder2messages subUrl)

                        "example-3" ->
                            ShowExample Example3 :: List.map Example3Action (Example3.builder2messages extractPath subUrl)

                        "example-4" ->
                            ShowExample Example4 :: List.map Example4Action (Example4.builder2messages extractPath subUrl)

                        "example-5" ->
                            ShowExample Example5 :: List.map Example5Action (Example5.builder2messages extractPath subUrl)

                        "example-6" ->
                            ShowExample Example6 :: List.map Example6Action (Example6.builder2messages extractPath subUrl)

                        "example-7" ->
                            ShowExample Example7 :: List.map Example7Action (Example7.builder2messages extractPath subUrl)

                        "example-8" ->
                            ShowExample Example8 :: List.map Example8Action (Example8.builder2messages subUrl)

                        originalPathSegment ->
                            let
                                originalPathSegmentsPlus =
                                    Just <|
                                        case originalPathSegment == "" of
                                            True ->
                                                []

                                            False ->
                                                case originalPathSegments of
                                                    Just segs ->
                                                        segs ++ [ originalPathSegment ]

                                                    Nothing ->
                                                        [ originalPathSegment ]
                            in
                            builder2messages originalPathSegmentsPlus extractPath insertPath subUrl

                _ ->
                    noMore
