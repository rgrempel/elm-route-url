module RouteUrl exposing
    ( App
    , UrlChange(..), HistoryEntry(..)
    , program, RouteUrlProgram
    , NavigationApp, navigationApp, runNavigationApp
    , WrappedModel, unwrapModel, mapModel
    , WrappedMsg, unwrapMsg, wrapUserMsg, wrapLocation
    )

{-| This module provides routing for single-page apps based on changes to the
the browser's location. The routing happens in both directions
-- that is, changes to the browser's location are translated to messages
your app can respond to, and changes to your app's state are translated to
changes in the browser's location. The net effect is to make it possible for
the 'back' and 'forward' buttons in the browser to do useful things, and for
the state of your app to be partially bookmark-able.

It is, of course, possible to do something like this using
[`elm/browser`](https://package.elm-lang.org/packages/elm/browser/latest)
by itself. For a discussion of the
differences between the official module and this one, see the
[package documentation](https://package.elm-lang.org/packages/rgrempel/elm-route-url/latest).


# Configuration

You configure this module by providing the functions set out in [`App`](#App).

@docs App


# URL Changes

You use `UrlChange` and `HistoryEntry` to indicate changes to the URL to be
displayed in the browser's location bar.

@docs UrlChange, HistoryEntry


# Initialization (the simple version)

The simplest way to use this module is to do something like this:

  - Define your [`App`](#App) record.

  - Use [`program`](#program) to
    create your `main` function, instead of [`Browser.application`](https://package.elm-lang.org/packages/elm/browser/latest/Browser#application).

@docs program, RouteUrlProgram


# More complex initialization

If your initialization needs are more complex, you may find some of the
remaining types and function to be of interest. You won't usually
need them.

@docs NavigationApp, navigationApp, runNavigationApp
@docs WrappedModel, unwrapModel, mapModel
@docs WrappedMsg, unwrapMsg, wrapUserMsg, wrapLocation

-}

import Browser exposing (..)
import Browser.Navigation exposing (..)
import Html exposing (Html)
import Update.Extra exposing (sequence)
import Url exposing (..)



-- THINGS CLIENTS PROVIDE


{-| The configuration required to use this module to create a `Browser.application`.

The `init`, `update`, `subscriptions`, and `view` fields have the same meaning
as they do in [`Browser.application`](https://package.elm-lang.org/packages/elm/browser/latest/Browser#application)
-- that is, you should provide what you normally provide to that function.

So, the "special" fields are the `delta2url`, `location2messages`, and `onExternalUrlRequest` functions.

  - `delta2url` will be called when your model changes. The first parameter is
    the model's previous value, and the second is the model's new value.

    Your function should return a `Just UrlChange` if a new URL should be
    displayed in the browser's location bar (or `Nothing` if no change to the URL
    is needed). This library will check the current URL before setting a new one,
    so you need not worry about setting duplicate URLs -- that will be
    automatically avoided.

    The reason we provide both the previous and current model for your
    consideration is that sometimes you may want to do something differently
    depending on the nature of the change in the model, not just the new value.
    For instance, it might make the difference between using `NewEntry` or
    `ModifyEntry` to make the change.

    Note that this function will _not_ be called when processing messages
    returned from your `location2messages` function, since in that case the
    URL has already been set.

  - `location2messages` will be called when a change in the browser's URL is
    detected, either because the user followed a link, typed something in the
    location bar, or used the back or forward buttons.

    Note that this function will _not_ be called when your `delta2url` method
    initiates a `UrlChange` -- since in that case, the relevant change in the
    model has already occurred.

    Your function should return a list of messages that your `update` function
    can respond to. Those messages will be fed into your app, to produce the
    changes to the model that the new URL implies.

  - `onExternalUrlRequest` is very similar to `Browser.application`'s `onUrlRequest`,
    but since the preceding two functions handle everything involved with internal
    `UrlRequest`s, this function only needs to handle the external case. As such, its
    argument is a `String`, mirroring the `External String` variant of [`Browser.UrlRequest`](https://package.elm-lang.org/packages/elm/browser/latest/Browser#UrlRequest).

-}
type alias App model msg flags =
    { delta2url : model -> model -> Maybe UrlChange
    , location2messages : Url -> List msg
    , init : flags -> Key -> ( model, Cmd msg )
    , update : msg -> model -> ( model, Cmd msg )
    , subscriptions : model -> Sub msg
    , view : model -> Document msg
    , onExternalUrlRequest : String -> msg
    }



-- SUPPORTING TYPES


{-| Indicates a change to be made in the URL, either creating
a new entry in the browser's history (`NewEntry`), or merely replacing the
current URL (`ModifyEntry`).

This is ultimately implemented via
[`Browser.Navigation.pushUrl`](https://package.elm-lang.org/packages/elm/browser/latest/Browser-Navigation#pushUrl) or
[`Browser.Navigation.replaceUrl`](https://package.elm-lang.org/packages/elm/browser/latest/Browser-Navigation#replaceUrl).
The reason we use this intermediate type is so that we can check whether the
provided `UrlChange` already corresponds to the current URL. In that case, we can
avoid creating a spurious duplicate entry in the browser's history.

The `path`, `query`, and `fragment` `String`s have exactly the same meaning as
their analogs in [`Url.Url`](https://package.elm-lang.org/packages/elm/url/latest/Url#Url).
In particular, these strings must already be uri-encoded.

Important Note: the `path` must be absolute. If it is not, `RouteUrl` will prepend a `/` to make it absolute. This
is necessary in order to prevent `Url.toString` from converting `{host = "example.com", path = "relative/path"}` into
`example.comrelative/path`, which will in turn cause a runtime exception from `history.pushState()` because you're not
allowed to change the host name. If you need to make relative paths based on your app's initial path, you must store
the initial path in your model and concatenate it when creating your `UrlChange`s.

Use the narrowest type you can that captures the change you want to make. For
instance, if the path and query parts of your URL should remain the same and only
the fragment should change, don't bother creating a `NewPath` that copies those parts.

This type does not let you alter the scheme, host, or authentication
method -- that is, no "<https://elm-lang.org">. You also cannot use relative
URLs; the `path` is always treated as absolute. (Let me know if you'd like relative
URLs -- we might be able to do something sensible with them, but we don't yet in this
version).

-}
type UrlChange
    = NewPath
        HistoryEntry
        { path : String
        , query : Maybe String
        , fragment : Maybe String
        }
    | NewQuery
        HistoryEntry
        { query : String
        , fragment : Maybe String
        }
    | NewFragment HistoryEntry String


{-| Indicates whether to create a new entry in the browser's history, or merely
modify the current entry.

One could have used a `Bool` for this instead, but I hate remembering what
`True` actually means.

-}
type HistoryEntry
    = NewEntry
    | ModifyEntry


{-| This is the router's part of the larger model.

`reportedUrl` is the last Url reported to us by the `Browser` module.

`expectedUrlChanges` represents how many outstanding commands we've
sent to change the URL. We increment it when we send a command, and
decrement it when we get one from `Browser` (unless it's already zero,
of course).

`key` is the `Browser.Navigation.Key` that's needed to invoke
`pushUrl` and `replaceUrl`.

-}
type alias RouterModel =
    { reportedUrl : Url
    , expectedUrlChanges : Int
    , key : Key
    }


{-| This is the model used by `RouteUrl`. In part, it is composed of the client's
model, and in part it is composed of things which `RouteUrl` wants to keep track of.
-}
type WrappedModel user
    = WrappedModel user RouterModel


{-| Given the wrapped model that `RouteUrl` uses, extract the part of the model
that your program provided.
-}
unwrapModel : WrappedModel user -> user
unwrapModel (WrappedModel user _) =
    user


{-| Given the wrapped model that `RouteUrl` uses, and a function that modifies
the part which your program provided, produce a new wrapped model.
-}
mapModel : (user -> user) -> WrappedModel user -> WrappedModel user
mapModel mapper (WrappedModel user router) =
    WrappedModel (mapper user) router


{-| This is the wrapper for RouteUrl's messages. Some messages are handled
internally by RouteUrl, and others are passed on to the application.
-}
type WrappedMsg user
    = RouterMsgOnUrlChange Url
    | RouterMsgOnUrlRequestInternal Url
    | UserMsg user


{-| Given the wrapped msg type that `RouteUrl` uses, either apply a function
that works on a `Url` (a request, in the first case; or a change, in the second case),
or apply a function that works on the msg type
that your program uses.
-}
unwrapMsg : (Url -> a) -> (Url -> a) -> (user -> a) -> WrappedMsg user -> a
unwrapMsg handleUrlRequestInternal handleUrlChange handleUserMsg wrapped =
    case wrapped of
        RouterMsgOnUrlRequestInternal url ->
            handleUrlRequestInternal url

        RouterMsgOnUrlChange url ->
            handleUrlChange url

        UserMsg msg ->
            handleUserMsg msg


{-| Given the kind of message your program uses, wrap it in the kind of msg
`RouteUrl` uses.
-}
wrapUserMsg : user -> WrappedMsg user
wrapUserMsg =
    UserMsg


{-| Given a `Url`, make the kind of message that `RouteUrl` uses to when a request
is made to navigate to that Url (for example, when the user clicks on a link)

I'm not sure you'll ever need this ... perhaps for testing?

-}
wrapLocation : Url -> WrappedMsg user
wrapLocation =
    RouterMsgOnUrlRequestInternal



-- ACTUALLY CREATING A PROGRAM


{-| A type which represents the various inputs to
[`Browser.application`](https://package.elm-lang.org/packages/elm/browser/latest/Browser#application).

You can produce this via [`navigationApp`](#navigationApp). Then, you can supply
this to [`runNavigationApp`](#runNavigationApp) in order to create a `Program`.

Normally you don't need this -- you can just use [`program`](#program).
However, `NavigationApp` could be useful if you want to do any further wrapping
of its functions.

-}
type alias NavigationApp model msg flags =
    { locationToMessage : Url -> msg
    , init : flags -> Url -> Key -> ( model, Cmd msg )
    , update : msg -> model -> ( model, Cmd msg )
    , view : model -> Document msg
    , subscriptions : model -> Sub msg
    , onUrlRequest : UrlRequest -> msg
    }


{-| Given your configuration, this function does some wrapping and produces
the functions which
[`Browser.application`](https://package.elm-lang.org/packages/elm/browser/latest/Browser#application)
requires.

Normally, you don't need this -- you can just use [`program`](#program).

-}
navigationApp : App model msg flags -> NavigationApp (WrappedModel model) (WrappedMsg msg) flags
navigationApp app =
    { locationToMessage = RouterMsgOnUrlChange
    , init = init app.init app
    , update = update app
    , view = view app
    , subscriptions = subscriptions app
    , onUrlRequest = onUrlRequest app
    }


{-| Turns the output from [`navigationApp`](#navigationApp)
into a `Program` that you can assign to your `main` function.

For convenience, you will usually want to just use [`program`](#program),
which goes directly from the required
configuration to a `Program`. You would only want `runNavigationApp` for the
sake of composability -- that is, in case there is something further you want
to do with the `NavigationApp` structure before turning it into a `Program`.

-}
runNavigationApp : NavigationApp model msg flags -> Program flags model msg
runNavigationApp app =
    Browser.application
        { init = app.init
        , update = app.update
        , view = app.view
        , onUrlChange = app.locationToMessage
        , onUrlRequest = app.onUrlRequest
        , subscriptions = app.subscriptions
        }


{-| A convenient alias for the `Program` type that lets you specify your
type for the `flags`, `model` and `msg` ... the alias takes care of the wrapping
that `RouteUrl` supplies.

For instance, suppose your `main` function would normally be typed like this:

    main : Program () Model Msg

Now, once you use `RouteUrl.program` to set things up, `RouteUrl` wraps your
model and msg types, so that the signature for your `main` function would
now be:

    main : Program () (WrappedModel Model) (WrappedMsg Msg)

But that's a little ugly. So, if you like, you can use the `RouteUrlProgram`
alias like this:

    main : RouteUrlProgram () Model Msg

It's exactly the same type, but looks a little nicer.

-}
type alias RouteUrlProgram flags model msg =
    Program flags (WrappedModel model) (WrappedMsg msg)


{-| Turns your configuration into a `Program` that you can assign to your
`main` function.
-}
program : App model msg flags -> RouteUrlProgram flags model msg
program =
    runNavigationApp << navigationApp



-- IMPLEMENTATION


{-| Call the provided view function with the user's part of the model
-}
view : App model msg flags -> WrappedModel model -> Document (WrappedMsg msg)
view app (WrappedModel model _) =
    let
        docMap fn doc =
            { title = doc.title
            , body = List.map (Html.map fn) doc.body
            }
    in
    app.view model
        |> docMap UserMsg


{-| Call the provided subscriptions function with the user's part of the model
-}
subscriptions : App model msg flags -> WrappedModel model -> Sub (WrappedMsg msg)
subscriptions app (WrappedModel model _) =
    app.subscriptions model
        |> Sub.map UserMsg


{-| Handle the given `UrlRequest`: internal requests are routed through our `update` function,
while external requests are passed to the App's onExternalUrlRequest function and the resulting
message is wrapped in `UserMsg`
-}
onUrlRequest : App model msg flags -> UrlRequest -> WrappedMsg msg
onUrlRequest app req =
    case req of
        Internal location ->
            RouterMsgOnUrlRequestInternal location

        External location ->
            app.onExternalUrlRequest location |> UserMsg


{-| Call the provided init function with the user's part of the model
-}
init : (flags -> Key -> ( model, Cmd msg )) -> App model msg flags -> flags -> Url -> Key -> ( WrappedModel model, Cmd (WrappedMsg msg) )
init appInit app flags location key =
    let
        ( userModel, command ) =
            appInit flags key
                |> sequence app.update (app.location2messages location)

        routerModel =
            { expectedUrlChanges = 0
            , reportedUrl = location
            , key = key
            }
    in
    ( WrappedModel userModel routerModel
    , Cmd.map UserMsg command
    )


{-| Extract the `HistoryEntry` part of the given `UrlChange`
-}
getHistoryEntry : UrlChange -> HistoryEntry
getHistoryEntry urlChange =
    case urlChange of
        NewPath historyEntry _ ->
            historyEntry

        NewQuery historyEntry _ ->
            historyEntry

        NewFragment historyEntry _ ->
            historyEntry


{-| create a new `Url` that's the result of applying the given change to the given url
-}
apply : Url -> UrlChange -> Url
apply url change =
    case change of
        NewPath _ c ->
            let
                {- If we don't force the path to be absolute, we risk causing an error like:

                   Uncaught DOMException: Failed to execute 'pushState' on 'History':
                   A history state object with URL 'http://example.comrelative/path'
                   cannot be created in a document with origin 'http://example.com'
                   and URL 'http://example.com/original/application/path'

                   The user likely intended to make the path be `/original/application/path/relative/path'
                   in the preceding example, but we can't know that for sure, and we've already advised
                   of this risk in the documentation for `UrlChange`
                -}
                absolutePath =
                    case String.startsWith "/" c.path of
                        True ->
                            c.path

                        False ->
                            "/" ++ c.path
            in
            { url
                | path = absolutePath
                , query = c.query
                , fragment = c.fragment
            }

        NewQuery _ c ->
            { url
                | query = Just c.query
                , fragment = c.fragment
            }

        NewFragment _ c ->
            { url | fragment = Just c }


{-| Interprets the UrlChange as a Cmd
-}
urlChange2Cmd : Key -> Url -> UrlChange -> Cmd msg
urlChange2Cmd key oldUrl change =
    apply oldUrl change
        |> toString
        |> (case getHistoryEntry change of
                NewEntry ->
                    pushUrl key

                ModifyEntry ->
                    replaceUrl key
           )


{-| If the given change actually chages the given url, return `Just` that change;
otherwise, return `Nothing`
-}
checkDistinctUrl : Url -> UrlChange -> Maybe UrlChange
checkDistinctUrl old new =
    let
        newUrl =
            apply old new
    in
    case old == newUrl of
        True ->
            Nothing

        False ->
            Just new


{-| This is the normal `update` function we're providing to `Navigation`.
-}
update : App model msg flags -> WrappedMsg msg -> WrappedModel model -> ( WrappedModel model, Cmd (WrappedMsg msg) )
update app msg (WrappedModel user router) =
    case msg of
        RouterMsgOnUrlRequestInternal requestedUrl ->
            -- note: we do *not* increment expectedUrlChanges here, because we are *not* doing
            -- this url change in response to a change in the app's state, but rather this is
            -- an href which came from "outside" (as discussed below)
            ( WrappedModel user router
            , pushUrl router.key <| Url.toString requestedUrl
            )

        RouterMsgOnUrlChange location ->
            let
                -- This is the same, no matter which path we follow below. Basically,
                -- we're keeping track of the last reported Url (i.e. what's in the location
                -- bar now), and all the hrefs which we expect (because we've set them
                -- ourselves). So, we remove the current href from the expectations.
                newRouterModel =
                    { reportedUrl =
                        location
                    , expectedUrlChanges =
                        if router.expectedUrlChanges > 0 then
                            router.expectedUrlChanges - 1

                        else
                            0
                    , key = router.key
                    }
            in
            if router.expectedUrlChanges > 0 then
                -- This is a Url change which we were expecting, because we did
                -- it in response to a change in the app's state.  So, we don't
                -- make any *further* change to the app's state here ... we
                -- just record that we've seen the Url change we expected.
                ( WrappedModel user newRouterModel
                , Cmd.none
                )

            else
                -- This is an href which came from the outside ... i.e. clicking on a link,
                -- typing in the location bar, following a bookmark. So, we need to update
                -- the app's state to correspond to the new location.
                let
                    ( newUserModel, commands ) =
                        sequence app.update (app.location2messages location) ( user, Cmd.none )
                in
                ( WrappedModel newUserModel newRouterModel
                , Cmd.map UserMsg commands
                )

        UserMsg userMsg ->
            let
                ( newUserModel, userCommand ) =
                    -- Here we "delegate" to the `update` function provided by the user
                    app.update userMsg user

                maybeUrlChange =
                    app.delta2url user newUserModel
                        |> Maybe.andThen (checkDistinctUrl router.reportedUrl)
            in
            case maybeUrlChange of
                Just urlChange ->
                    ( WrappedModel newUserModel <|
                        { reportedUrl = apply router.reportedUrl urlChange
                        , expectedUrlChanges = router.expectedUrlChanges + 1
                        , key = router.key
                        }
                    , Cmd.map UserMsg <| Cmd.batch [ urlChange2Cmd router.key router.reportedUrl urlChange, userCommand ]
                    )

                Nothing ->
                    ( WrappedModel newUserModel router
                    , Cmd.map UserMsg userCommand
                    )
