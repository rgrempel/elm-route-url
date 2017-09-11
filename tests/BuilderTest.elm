module BuilderTest exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import RouteUrl.Builder exposing (..)
import RouteUrl exposing (..)
import Test exposing (..)


fixture : Builder
fixture =
    builder
        |> replaceQuery
            [ ( "a", "7" )
            , ( "b", "8" )
            , ( "c", "9" )
            , ( "b", "10" )
            , ( "e", "14" )
            ]


fuzzQuery : Fuzzer (List ( String, String ))
fuzzQuery =
    Fuzz.list (Fuzz.tuple ( Fuzz.string, Fuzz.string ))


toUrlChangeTest : Test
toUrlChangeTest =
    describe "toUrlChange"
        [ test "preserves order" <|
            \() ->
                fixture
                    |> toUrlChange
                    |> Expect.equal
                        (UrlChange NewEntry "/?a=7&b=8&c=9&b=10&e=14")
        , fuzz fuzzQuery "will round-trip" <|
            \randomQuery ->
                builder
                    |> replaceQuery randomQuery
                    |> toUrlChange
                    |> .url
                    |> fromUrl
                    |> query
                    |> Expect.equal randomQuery
        ]


addQueryTest : Test
addQueryTest =
    describe "addQuery"
        [ test "adds new keys to the end" <|
            \() ->
                fixture
                    |> addQuery "z" "102"
                    |> query
                    |> Expect.equal
                        [ ( "a", "7" )
                        , ( "b", "8" )
                        , ( "c", "9" )
                        , ( "b", "10" )
                        , ( "e", "14" )
                        , ( "z", "102" )
                        ]
        , test "adds existing keys to the end, and keeps old key" <|
            \() ->
                fixture
                    |> addQuery "a" "103"
                    |> query
                    |> Expect.equal
                        [ ( "a", "7" )
                        , ( "b", "8" )
                        , ( "c", "9" )
                        , ( "b", "10" )
                        , ( "e", "14" )
                        , ( "a", "103" )
                        ]
        ]


removeQueryTest : Test
removeQueryTest =
    describe "removeQuery"
        [ test "removes one" <|
            \() ->
                fixture
                    |> removeQuery "a"
                    |> query
                    |> Expect.equal
                        [ ( "b", "8" )
                        , ( "c", "9" )
                        , ( "b", "10" )
                        , ( "e", "14" )
                        ]
        , test "removes multiple" <|
            \() ->
                fixture
                    |> removeQuery "b"
                    |> query
                    |> Expect.equal
                        [ ( "a", "7" )
                        , ( "c", "9" )
                        , ( "e", "14" )
                        ]
        ]


getQueryTest : Test
getQueryTest =
    describe "getQuery"
        [ test "with one" <|
            \() ->
                fixture
                    |> getQuery "a"
                    |> Expect.equal [ "7" ]
        , test "with two" <|
            \() ->
                fixture
                    |> getQuery "b"
                    |> Expect.equal [ "8", "10" ]
        , test "with none" <|
            \() ->
                fixture
                    |> getQuery "notthere"
                    |> Expect.equal []
        ]


insertQueryTest : Test
insertQueryTest =
    describe "insertQuery"
        [ test "adds new keys to the end" <|
            \() ->
                fixture
                    |> insertQuery "z" "102"
                    |> query
                    |> Expect.equal
                        [ ( "a", "7" )
                        , ( "b", "8" )
                        , ( "c", "9" )
                        , ( "b", "10" )
                        , ( "e", "14" )
                        , ( "z", "102" )
                        ]
        , test "modifies existing key where it was (first)" <|
            \() ->
                fixture
                    |> insertQuery "a" "103"
                    |> query
                    |> Expect.equal
                        [ ( "a", "103" )
                        , ( "b", "8" )
                        , ( "c", "9" )
                        , ( "b", "10" )
                        , ( "e", "14" )
                        ]
        , test "modifies existing key where it was (third)" <|
            \() ->
                fixture
                    |> insertQuery "c" "104"
                    |> query
                    |> Expect.equal
                        [ ( "a", "7" )
                        , ( "b", "8" )
                        , ( "c", "104" )
                        , ( "b", "10" )
                        , ( "e", "14" )
                        ]
        , test "replaces multiple key/values pairs at first position" <|
            \() ->
                fixture
                    |> insertQuery "b" "105"
                    |> query
                    |> Expect.equal
                        [ ( "a", "7" )
                        , ( "b", "105" )
                        , ( "c", "9" )
                        , ( "e", "14" )
                        ]
        ]
