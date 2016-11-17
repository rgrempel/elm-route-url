module RouteUrl
    exposing
        ( App
        , AppWithFlags
        , UrlChange
        , HistoryEntry(NewEntry, ModifyEntry)
        , NavigationApp
        , NavigationAppWithFlags
        , Model
        , Msg
        , navigationApp
        , navigationAppWithFlags
        , runNavigationApp
        , runNavigationAppWithFlags
        , program
        , programWithFlags
        )

{-| This module provides routing for single-page apps based on changes to the
 the browser's location. The routing happens in both directions
-- that is, changes to the browser's location are translated to messages
your app can respond to, and changes to your app's state are translated to
changes in the browser's location. The net effect is to make it possible for
the 'back' and 'forward' buttons in the browser to do useful things, and for
the state of your app to be partially bookmark-able.

It is, of course, possible to do something like this using
[`elm-lang/navigation`](http://package.elm-lang.org/packages/elm-lang/navigation/latest)
by itself. For a discussion of the
differences between the official module and this one, see the [package documentation]
(http://package.elm-lang.org/packages/rgrempel/elm-route-url/latest).

# Configuration

You configure this module by providing the functions set out in [`App`](#App) or
[`AppWithFlags`](#AppWithFlags), depending on what kind of `init` function you
want to use.

@docs App, AppWithFlags

# URL Changes

You use `UrlChange` and `HistoryEntry` to indicate changes to the URL to be
displayed in the browser's location bar.

@docs UrlChange, HistoryEntry

# Router Model

The `RouteUrl.Model` holds routing information.

@docs Model

The `RouteUrl.Msg` encapsulates two types of messages.

@docs Msg

# Initialization (the simple version)

The simplest way to use this module is to do something like this:

* Define your [`App`](#App) or [`AppWithFlags`](#AppWithFlags) record.

* Use [`program`](#program) or [`programWithFlags`](#programWithFlags) to
  create your `main` function, instead of their homonymous equivalents in
  [`Html`](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html).

@docs program, programWithFlags

# More complex initialization (not usually needed)

@docs NavigationApp, NavigationAppWithFlags
@docs navigationApp, navigationAppWithFlags
@docs runNavigationApp, runNavigationAppWithFlags
-}

import Navigation exposing (Location)
import Html exposing (Html)
import Erl exposing (Url)
import String exposing (startsWith)
import Dict


-- THINGS CLIENTS PROVIDE


{-| The configuration required to use this module to create a `Program`.

The `init`, `update`, `subscriptions` and `view` fields have the same meaning
as they do in [`Html.program`](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#program)
-- that is, you should provide what you normally provide to that function.

So, the "special" fields are the `delta2url` function and the
`location2messages` function.

* `delta2url` will be called when your model changes. The first parameter is
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

  Note that this function will *not* be called when processing messages
  returned from your `location2messages` function, since in that case the
  URL has already been set.

  If you are familiar with elm-route-hash, `delta2url` is analogous to the old
  `delta2update` function -- just renamed to reflect the fact that you can
  change the whole URL now, not just the hash.

* `location2messages` will be called when a change in the browser's URL is
  detected, either because the user followed a link, typed something in the
  location bar, or used the back or forward buttons.

  Note that this function will *not* be called when your `delta2url` method
  initiates a `UrlChange` -- since in that case, the relevant change in the
  model has already occurred.

  Your function should return a list of messages that your `update` function
  can respond to. Those messages will be fed into your app, to produce the
  changes to the model that the new URL implies.

  If you are familiar with elm-route-hash, `location2messages` is analogous to
  the old `location2actions` function -- just renamed to reflected the
  terminology change from `action` to `msg` in Elm 0.17.
-}
type alias App model msg =
    { delta2url : model -> model -> Maybe UrlChange
    , location2messages : Location -> List msg
    , init : ( model, Cmd msg )
    , update : msg -> model -> ( model, Cmd msg )
    , subscriptions : model -> Sub msg
    , view : model -> Html msg
    }


{-| The configuration needed to use this module to make a `Program flags`.

The `init`, `update`, `subscriptions` and `view` fields have the same meaning
as they do in
[`Html.programWithFlags`](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#programWithFlags)
-- that is, you should provide what you normally provide to that function.

So, the special functions are `delta2url` and `location2messages`,
which are described above, under [`App`](#App).
-}
type alias AppWithFlags model msg flags =
    { delta2url : model -> model -> Maybe UrlChange
    , location2messages : Location -> List msg
    , init : flags -> ( model, Cmd msg )
    , update : msg -> model -> ( model, Cmd msg )
    , subscriptions : model -> Sub msg
    , view : model -> Html msg
    }



-- SUPPORTING TYPES


{-| Indicates a change to be made in the URL, either creating
a new entry in the browser's history (`NewEntry`), or merely replacing the
current URL (`ModifyEntry`).

This is ultimately implemented via
[`Navigation.newUrl`](http://package.elm-lang.org/packages/elm-lang/navigation/1.0.0/Navigation#newUrl) or
[`Navigation.modifyUrl`](http://package.elm-lang.org/packages/elm-lang/navigation/1.0.0/Navigation#modifyUrl).
The reason we use this intermediate type is so that we can check whether the
provided string already corresponds to the current URL. In that case, we can
avoid creating a spurious duplicate entry in the browser's history.

The reason we take a `String` (rather than a more structured type) is that
there may be several ways you might want to build up the required URL. We
don't want to be prescriptive about that. However, the `String` you provide
must follow a couple of rules.

* The `String` must already be uri-encoded.

* The `String` must either start with a '/', a `?' or a '#'.

    * If it starts with a '/', it will be interpreted as a full path, including
      optional query parameters and hash.

    * If it starts with a '?', then we'll assume that you want the current
      path to stay the same -- only the query parameters and hash will change.

    * If it starts with a '#', then we'll assume that you want the current
      path and query parameters (if any) to stay the same -- only the
      hash will change.

So, what you should *not* provide is the scheme, host, or authentication
method -- that is, no "http://elm-lang.org". You should also not use relative
URLs. (Let me know if you'd like relative URLs -- we might be able to do
something sensible with them, but we don't yet in this version).

One way to construct a `UrlChange` in a modular way is to use the
`RouteUrl.Builder` module. However, a variety of approaches are possible.
-}
type alias UrlChange =
    { entry : HistoryEntry
    , url : String
    }


{-| Indicates whether to create a new entry in the browser's history, or merely
modify the current entry.

One could have used a `Bool` for this instead, but I hate remembering what
`True` actually means.
-}
type HistoryEntry
    = NewEntry
    | ModifyEntry



-- This is the router's part of the larger model.
--
-- `reportedUrl` is the last Url reported to us via urlUpdate.
--
-- `expectedUrlUpdates` represents how many outstanding commands we've
-- sent to change the URL. We increment it when we send a command, and
-- decrement it when `urlUpdate` is called (unless it's already zero,
-- of course).


type alias RouterModel =
    { reportedUrl : Url
    , expectedUrlUpdates : Int
    }


{-| This is the model we feed into `Navigation` ... so, in part it is the user's
model, and in part it is the stuff that we want to keep track of internally.
-}
type alias Model user =
    { user : user
    , router : RouterModel
    }



{-| This is the wrapper for RouteUrl's App's messages.

A `RouterMsg` is a msg coming from a change in location.  A `RouterMsg` gets
processed by our `UrlUpdate` function, which in turn passes the location
to the user's `location2messages` function.

A `UserMsg` is a non-location message generated by the user's app,
and is handled by the user's `update` function.
-}
type Msg msg
    = RouterMsg Location
    | UserMsg msg



-- ACTUALLY CREATING A PROGRAM


{-| A type which represents the various inputs to
[`Navigation.program`](http://package.elm-lang.org/packages/elm-lang/navigation/2.0.0/Navigation#program).

You can produce this via [`navigationApp`](#navigationApp). Then, you can supply
this to [`runNavigationApp`](#runNavigationApp) in order to create a `Program`.

Normally you don't need this -- you can just use [`program`](#program).
However, `NavigationApp` could be useful if you want to do any further wrapping
of its functions.
-}
type alias NavigationApp model msg =
    { init : Location -> ( Model model, Cmd (Msg msg) )
    , update : Msg msg -> Model model -> ( Model model, Cmd (Msg msg) )
    , view : Model model -> Html (Msg msg)
    , subscriptions : Model model -> Sub (Msg msg)
    }


{-| A type which represents the various inputs to
[`Navigation.programWithFlags`](http://package.elm-lang.org/packages/elm-lang/navigation/2.0.0/Navigation#programWithFlags).

You can produce this via [`navigationAppWithFlags`](#navigationAppWithFlags).
Then, you can supply this to [`runNavigationApp`](#runNavigationApp) in order
to create a `Program flags`.

Normally you don't need this -- you can just use
[`programWithFlags`](#programWithFlags). However, `NavigationAppWithFlags`
could be useful if you want to do any further wrapping of its functions.
-}
type alias NavigationAppWithFlags model msg flags =
    { init : flags -> Location -> ( Model model, Cmd (Msg msg) )
    , update : Msg msg -> Model model -> ( Model model, Cmd (Msg msg) )
    , view : Model model -> Html (Msg msg)
    , subscriptions : Model model -> Sub (Msg msg)
    }


{-| Given your configuration, this function does some wrapping and produces
the functions which
[`Navigation.program`](http://package.elm-lang.org/packages/elm-lang/navigation/2.0.0/Navigation#program)
requires.

Normally, you don't need this -- you can just use [`program`](#program).
-}
navigationApp : App model msg -> NavigationApp model msg
navigationApp app =
    { init = init_ app
    , update = update_ app
    , view = view_ app
    , subscriptions = subscriptions_ app
    }


{-| Given your configuration, this function does some wrapping and produces
the functions which
[`Navigation.programWithFlags`](http://package.elm-lang.org/packages/elm-lang/navigation/2.0.0/Navigation#programWithFlags)
requires.

Normally, you don't need this -- you can just use [`programWithFlags`](#programWithFlags).
-}
navigationAppWithFlags : AppWithFlags model msg flags -> NavigationAppWithFlags model msg flags
navigationAppWithFlags app =
    { init = init app
    , update = update app
    , view = view app
    , subscriptions = subscriptions app
    }


{-| Turns the output from [`navigationApp`](#navigationApp)
into a `Program` that you can assign to your `main` function.

For convenience, you will usually want to just use [`program`](#program),
which goes directly from the required
configuration to a `Program`. You would only want `runNavigationApp` for the
sake of composability -- that is, in case there is something further you want
to do with the `NavigationApp` structure before turning it into a `Program`.
-}
runNavigationApp : NavigationApp model msg -> Program Never (Model model) (Msg msg)
runNavigationApp app =
    Navigation.program (\location -> RouterMsg location)
        { init = app.init
        , update = app.update
        , view = app.view
        , subscriptions = app.subscriptions
        }


{-| Turns the output from [`navigationAppWithFlags`](#navigationAppWithFlags)
into a `Program flags` that you can assign to your `main` function.

For convenience, you will usually want to just use
[`programWithFlags`](#programWithFlags), which goes directly from the required
configuration to a `Program flags`. You would only want `runNavigationAppWithFlags`
for the sake of composability -- that is, in case there is something further
you want to do with the `NavigationApp` structure before turning it into a `Program flags`.
-}
runNavigationAppWithFlags : NavigationAppWithFlags model msg flags -> Program flags (Model model) (Msg msg)
runNavigationAppWithFlags app =
    Navigation.programWithFlags (\location -> RouterMsg location)
        { init = app.init
        , update = app.update
        , view = app.view
        , subscriptions = app.subscriptions
        }


{-| Turns your configuration into a `Program` that you can assign to your
`main` function.
-}
program : App model msg -> Program Never (Model model) (Msg msg)
program =
    runNavigationApp << navigationApp


{-| Turns your configuration into a `Program flags` that you can assign to your
`main` function.
-}
programWithFlags : AppWithFlags model msg flags -> Program flags (Model model) (Msg msg)
programWithFlags =
    runNavigationAppWithFlags << navigationAppWithFlags



-- IMPLEMENTATION
-- Call the provided view function with the user's part of the model


view : AppWithFlags model msg flags -> Model model -> Html (Msg msg)
view app model =
    Html.map UserMsg <| app.view model.user


view_ : App model msg -> Model model -> Html (Msg msg)
view_ app model =
    Html.map UserMsg <| app.view model.user



-- Call the provided subscriptions function with the user's part of the model


subscriptions : AppWithFlags model msg flags -> Model model -> Sub (Msg msg)
subscriptions app model =
    Sub.map UserMsg <| app.subscriptions model.user


subscriptions_ : App model msg -> Model model -> Sub (Msg msg)
subscriptions_ app model =
    Sub.map UserMsg <| app.subscriptions model.user



-- Call the provided init function with the user's part of the model


init : AppWithFlags model msg flags -> flags -> Location -> ( Model model, Cmd (Msg msg) )
init app flags location =
    initImpl app.update app.location2messages location (app.init flags)


init_ : App model msg -> Location -> ( Model model, Cmd (Msg msg) )
init_ app location =
    initImpl app.update app.location2messages location app.init



-- Common processing for init and init_, processing any messages
-- from the initial location.


initImpl
    : (xmsg -> model -> ( model, Cmd msg ))
    -> (Location -> List xmsg)
    -> Location
    -> ( model, Cmd msg )
    -> ( Model model, Cmd (Msg msg) )
initImpl upd l2m location ( userModelFromFlags, commandFromFlags ) =
    let
        locationMessages = l2m location
        (userModelFromLocation, commands) =
            processLocationMessages upd locationMessages userModelFromFlags [ commandFromFlags ]

        routerModel =
            { expectedUrlUpdates = 0
            , reportedUrl = Erl.parse location.href
            }
    in
        ( { user = userModelFromLocation
          , router = routerModel
          }
        , Cmd.map UserMsg <| Cmd.batch commands
        )



-- This function steps through the list of messages derived from the
-- app's location2messages function, and updates the apps user model,
-- returning the final state and any commands returned by the app's
-- update function.

processLocationMessages
    : (xmsg -> model -> ( model, Cmd msg ))
    -> List xmsg
    -> model
    -> List (Cmd msg)
    -> ( model, List (Cmd msg) )
processLocationMessages upd locationMessages userModel initialCommandList =
    let
        step msg (userModel, commandList) =
            case upd msg userModel of
                ( stepModel, stepCmd ) ->
                    ( stepModel, stepCmd :: commandList )
    in
        List.foldl step (userModel, initialCommandList) locationMessages



-- Interprets the UrlChange as a Cmd


urlChange2Cmd : UrlChange -> Cmd msg
urlChange2Cmd change =
    change.url
        |> case change.entry of
            NewEntry ->
                Navigation.newUrl

            ModifyEntry ->
                Navigation.modifyUrl


mapUrl : (String -> String) -> UrlChange -> UrlChange
mapUrl func c1 =
    { c1 | url = func c1.url }



-- Whether one Url is equal to another, for our purposes (that is, just comparing
-- the things we care about).


eqUrl : Url -> Url -> Bool
eqUrl u1 u2 =
    u1.path
        == u2.path
        && u1.hasTrailingSlash
        == u2.hasTrailingSlash
        && u1.hash
        == u2.hash
        && (Dict.toList u1.query)
        == (Dict.toList u2.query)


checkDistinctUrl : Url -> UrlChange -> Maybe UrlChange
checkDistinctUrl old new =
    if eqUrl (Erl.parse new.url) old then
        Nothing
    else
        Just new


url2path : Url -> String
url2path url =
    "/"
        ++ (String.join "/" url.path)
        ++ if url.hasTrailingSlash && not (List.isEmpty url.path) then
            "/"
           else
            ""



-- Supplies the default path or query string, if needed


normalizeUrl : Url -> UrlChange -> UrlChange
normalizeUrl old change =
    mapUrl
        (if startsWith "?" change.url then
            \url -> url2path old ++ url
         else if startsWith "#" change.url then
            \url -> url2path old ++ Erl.queryToString old ++ url
         else
            \url -> url
        )
        change



-- This is the normal `update` function we're providing to `Navigation`.


update : AppWithFlags model msg flags -> Msg msg -> Model model -> ( Model model, Cmd (Msg msg) )
update app msg model =
    updateImpl app.update app.location2messages app.delta2url msg model


update_ : App model msg -> Msg msg -> Model model -> ( Model model, Cmd (Msg msg) )
update_ app msg model =
    updateImpl app.update app.location2messages app.delta2url msg model



-- Common processing for the app's update function.


updateImpl
    : (xmsg -> model -> ( model, Cmd msg ))
    -> ( Location -> List xmsg )
    -> (model -> model -> Maybe UrlChange)
    -> Msg xmsg
    -> Model model
    -> ( Model model, Cmd (Msg msg) )
updateImpl upd l2m d2u msg model =
    case msg of
        RouterMsg location ->
            -- Handle routing updates sent to us by the Navigation.program
            urlUpdateImpl upd l2m location model

        UserMsg userMsg ->
            -- Handle app-specific messages
            let
                ( newUserModel, userCommand ) =
                    -- Here we "delegate" to the `update` function provided by the user
                    upd userMsg model.user

                maybeUrlChange =
                    Maybe.map
                        (normalizeUrl model.router.reportedUrl)
                        (d2u model.user newUserModel)
                        |> Maybe.andThen (checkDistinctUrl model.router.reportedUrl)
            in
                case maybeUrlChange of
                    Just urlChange ->
                        ( { user = newUserModel
                          , router =
                                { reportedUrl = Erl.parse urlChange.url
                                , expectedUrlUpdates = model.router.expectedUrlUpdates + 1
                                }
                          }
                        , Cmd.map UserMsg <| Cmd.batch [ urlChange2Cmd urlChange, userCommand ]
                        )

                    Nothing ->
                        ( { user = newUserModel
                          , router = model.router
                          }
                        , Cmd.map UserMsg userCommand
                        )



-- This is the function which decides whether to tell the calling application's
-- `location2messages` method if a really new location has been sent to
-- us from outside the app.


urlUpdateImpl
    : (xmsg -> model -> ( model, Cmd msg ))
    -> (Location -> List xmsg)
    -> Location
    -> Model model
    -> ( Model model, Cmd (Msg msg) )
urlUpdateImpl upd l2m location model =
    let
        -- This is the same, no matter which path we follow below. Basically,
        -- we're keeping track of the last reported Url (i.e. what's in the location
        -- bar now), and all the hrefs which we expect (because we've set them
        -- ourselves). So, we remove the current href from the expectations.
        newRouterModel =
            { reportedUrl =
                Erl.parse location.href
            , expectedUrlUpdates =
                if model.router.expectedUrlUpdates > 0 then
                    model.router.expectedUrlUpdates - 1
                else
                    0
            }
    in
        if model.router.expectedUrlUpdates > 0 then
            -- This is a urlUpdate which we were expecting, because we did
            -- it in response to a change in the app's state.  So, we don't
            -- make any *further* change to the app's state here ... we
            -- just record that we've seen the urlUpdate we expected.
            ( { model | router = newRouterModel }
            , Cmd.none
            )
        else
            -- This is an href which came from the outside ... i.e. clicking on a link,
            -- typing in the location bar, following a bookmark. So, we need to update
            -- the app's state to correspond to the new location.
            let
                locationMessages = l2m location
                (userModelFromLocation, commands) =
                    processLocationMessages upd locationMessages model.user []
            in
                ( { user = userModelFromLocation
                  , router = newRouterModel
                  }
                , Cmd.map UserMsg <| Cmd.batch commands
                )
