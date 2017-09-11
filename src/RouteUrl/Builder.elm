module RouteUrl.Builder
    exposing
        ( Builder
        , builder
        , entry
        , newEntry
        , modifyEntry
        , path
        , modifyPath
        , prependToPath
        , appendToPath
        , replacePath
        , query
        , modifyQuery
        , insertQuery
        , addQuery
        , removeQuery
        , getQuery
        , replaceQuery
        , hash
        , modifyHash
        , replaceHash
        , toUrlChange
        , toHashChange
        , fromUrl
        , fromHash
        )

{-| This module provides a type which you can use to help construct a
`UrlChange` or parse a `Location`.

However, the `Builder` type is not really the focus of elm-route-url.

  - Ultimately, a `UrlChange` just requires a `String` -- you don't need to
    use this module to construct one.

  - You also don't need to use this module to parse a `Location` -- there are a
    fair number of relevant packages for that, including:
      - [evancz/url-parser](http://package.elm-lang.org/packages/evancz/url-parser/latest)
      - [Bogdanp/elm-combine](http://package.elm-lang.org/packages/Bogdanp/elm-combine/latest)
      - [Bogdanp/elm-route](http://package.elm-lang.org/packages/Bogdanp/elm-route/latest)
      - [etaque/elm-route-parser](http://package.elm-lang.org/packages/etaque/elm-route-parser/latest)
      - [poyang/elm-router](http://package.elm-lang.org/packages/poying/elm-router/latest)
      - [sporto/erl](http://package.elm-lang.org/packages/sporto/erl/latest)
      - [sporto/hop](http://package.elm-lang.org/packages/sporto/hop/latest)

So, this module is potentially useful, but there are quite a few other
options you may wish to investigate.

Note that you should not uri-encode anything provided to this module. That
will be done for you.


# Initialization

@docs Builder, builder


# Creating or modifying history entries

@docs entry, newEntry, modifyEntry


# Manipulating the path

@docs path, modifyPath, prependToPath, appendToPath, replacePath


# Manipulating the query

@docs query, modifyQuery, insertQuery, addQuery, removeQuery, getQuery, replaceQuery


# Manipulating the hash

@docs hash, modifyHash, replaceHash


# Conversion

@docs toUrlChange, toHashChange, fromUrl, fromHash

-}

import RouteUrl exposing (HistoryEntry(..), UrlChange)
import Dict exposing (Dict)
import Http exposing (encodeUri, decodeUri)
import Regex exposing (HowMany(..), replace, regex)
import String
import Erl


-- THE TYPE


{-| An opaque type which helps to build up a URL for a `URLChange`,
or parse a `Location`.

Start with [`builder`](#builder), and then use other functions to make changes.
Or, if you have a URL, start with [`fromUrl`](#fromUrl) or [`fromHash`](#fromHash).

-}
type Builder
    = Builder
        { entry : HistoryEntry
        , path : List String
        , query : List ( String, String )
        , hash : String
        }


{-| Creates a default `Builder`. Start with this, then use other methods
to build up the URL.

    url : Builder
    url =
        builder
            |> newEntry
            |> appendToPath [ "home" ]

-}
builder : Builder
builder =
    Builder
        { entry = NewEntry
        , path = []
        , query = []
        , hash = ""
        }



-- ENTRY


{-| Indicates whether the `Builder` will make a new entry in the browser's
history, or merely modify the current entry.
-}
entry : Builder -> HistoryEntry
entry (Builder builder) =
    builder.entry


{-| Make a new entry in the browser's history.
-}
newEntry : Builder -> Builder
newEntry (Builder builder) =
    Builder { builder | entry = NewEntry }


{-| Modify the current entry in the browser's history.
-}
modifyEntry : Builder -> Builder
modifyEntry (Builder builder) =
    Builder { builder | entry = ModifyEntry }



-- PATH


{-| The segments of the path. The path is represented by a list of strings.
Ultimately, they will be uri-encoded for you, and joined with a "/".
-}
path : Builder -> List String
path (Builder builder) =
    builder.path


{-| Replace the path with the result of a function which acts on
the current path.
-}
modifyPath : (List String -> List String) -> Builder -> Builder
modifyPath func (Builder builder) =
    Builder { builder | path = func builder.path }


{-| Add the provided list to the beginning of the builder's path.
-}
prependToPath : List String -> Builder -> Builder
prependToPath =
    modifyPath << List.append


{-| Add the provided list to the end of the builder's path.
-}
appendToPath : List String -> Builder -> Builder
appendToPath =
    modifyPath << flip List.append


{-| Sets the path to the provided list.
-}
replacePath : List String -> Builder -> Builder
replacePath list (Builder builder) =
    Builder { builder | path = list }



-- QUERY


{-| The query portion of the URL. It is represented by a `List` of
key/value pairs.
-}
query : Builder -> List ( String, String )
query (Builder builder) =
    builder.query


{-| Replace the query with the result of a function that acts on the current query.
-}
modifyQuery : (List ( String, String ) -> List ( String, String )) -> Builder -> Builder
modifyQuery func (Builder builder) =
    Builder { builder | query = func builder.query }


{-| Insert a key/value pair into the query. Replaces keys with the same name,
in case of collision.
-}
insertQuery : String -> String -> Builder -> Builder
insertQuery newKey newValue =
    modifyQuery
        (\query ->
            query
                |> List.foldl
                    (\( oldKey, oldValue ) ( acc, replaced ) ->
                        if newKey == oldKey then
                            -- If it's the key we're replacing, then see if
                            -- we've already done it.
                            if replaced then
                                -- If so, we just drop the old one ... the new
                                -- one has already been inserted
                                ( acc, replaced )
                            else
                                -- If not, we insert the new one instead of the
                                -- old one, and remember that we've done it.
                                ( ( newKey, newValue ) :: acc
                                , True
                                )
                        else
                            -- If it's some other key, just pass it through
                            ( ( oldKey, oldValue ) :: acc
                            , replaced
                            )
                    )
                    ( [], False )
                |> \( reversedList, replaced ) ->
                    -- Since we did a `foldl`, and then a bunch of `::`, the list
                    -- was reversed. So, check whether we still need to add our
                    -- new key, and then un-reverse. (This helps us put the new
                    -- key at the end, if it didn't exist before).
                    if replaced then
                        List.reverse reversedList
                    else
                        List.reverse <|
                            ( newKey, newValue )
                                :: reversedList
        )


{-| Add a key/value pair into the query. Does not replace a key with the same name ...
just adds another value.
-}
addQuery : String -> String -> Builder -> Builder
addQuery key value =
    modifyQuery (\query -> List.reverse (( key, value ) :: List.reverse query))


{-| Remove a query key.
-}
removeQuery : String -> Builder -> Builder
removeQuery key =
    modifyQuery (List.filter (\( k, _ ) -> k /= key))


{-| Get the values for a query key (can return multiple values if the key
is given more than once in the query).
-}
getQuery : String -> Builder -> List String
getQuery key (Builder builder) =
    builder.query
        |> List.filterMap
            (\( k, v ) ->
                if k == key then
                    Just v
                else
                    Nothing
            )


{-| Replace the whole query with a different list of key/value pairs.
-}
replaceQuery : List ( String, String ) -> Builder -> Builder
replaceQuery query (Builder builder) =
    Builder { builder | query = query }



-- HASH


{-| Gets the hash portion of the URL, without the "#".
-}
hash : Builder -> String
hash (Builder builder) =
    builder.hash


{-| Replace the hash with the result of a function applied to the current hash.
-}
modifyHash : (String -> String) -> Builder -> Builder
modifyHash func (Builder builder) =
    Builder { builder | hash = func builder.hash }


{-| Replace the hash with the provided value. Note that you should not include the "#".
-}
replaceHash : String -> Builder -> Builder
replaceHash hash (Builder builder) =
    Builder { builder | hash = hash }



-- CONVERSION


toChange : Bool -> Builder -> UrlChange
toChange stuffIntoHash (Builder builder) =
    let
        prefix =
            if stuffIntoHash then
                "#!/"
            else
                "/"

        queryPrefix =
            if stuffIntoHash then
                "^"
            else
                "?"

        joinedPath =
            String.join "/" (List.map encodeUri builder.path)

        joinedQuery =
            if List.isEmpty builder.query then
                ""
            else
                queryPrefix ++ String.join "&" (List.map eachQuery builder.query)

        eachQuery ( key, value ) =
            encodeUri key ++ "=" ++ encodeUri value

        hashPrefix =
            if stuffIntoHash then
                "$"
            else
                "#"

        formattedHash =
            if builder.hash == "" then
                ""
            else
                hashPrefix ++ encodeUri builder.hash
    in
        { entry = builder.entry
        , url = prefix ++ joinedPath ++ joinedQuery ++ formattedHash
        }


{-| Once you've built up your URL, use this to convert it to a `UrlChange` for use with
`RouteUrl`.
-}
toUrlChange : Builder -> UrlChange
toUrlChange =
    toChange False


{-| Like [`toUrlChange`](#toUrlChange), but puts everything into the hash, prepended by "#!".

If your `Builder` has a hash component, we'll use '$' instead of '#' to
delimit the embedded hash. And, we will use '^' instead of '?' to begin
the query parameters.

-}
toHashChange : Builder -> UrlChange
toHashChange =
    toChange True


{-| Constructs a `Builder` from a URL.
-}
fromUrl : String -> Builder
fromUrl url =
    let
        erl =
            Erl.parse url
    in
        Builder
            { entry = NewEntry
            , path = erl.path
            , query = erl.query

            -- note that Erl.parse doesn't seem to decode the hash for you
            , hash = Maybe.withDefault "" <| decodeUri erl.hash
            }


{-| Constructs a `Builder` from the hash portion of a URL.

  - Assumes that the hash starts with "#!/".

  - Assumes that any embedded hash is delimited with a '$' instead of a '#'.

  - Assumes that any embedded query parameters being with a '^' instead of
    a '?'.

-}
fromHash : String -> Builder
fromHash url =
    let
        unwrapped =
            Erl.parse url
                |> .hash
                |> replace (AtMost 1) (regex "^!") (always "")
                |> replace (AtMost 1) (regex "$") (always "#")
                |> replace (AtMost 1) (regex "\\^") (always "?")
                |> Erl.parse
    in
        Builder
            { entry = NewEntry
            , path = unwrapped.path
            , query = unwrapped.query
            , hash = unwrapped.hash
            }
