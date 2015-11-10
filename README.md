# elm-route-hash

This is a module for routing single-page-apps in Elm, building on the
[elm-history](http://package.elm-lang.org/packages/TheSeamau5/elm-history/latest)
package. The module is extracted from an
[application I'm working on](https://github.com/rgrempel/csrs-elm).

* [Overview](#overview)
    * [Routing](#routing)
        * [Mapping location changes to actions](#mapping-location-changes-to-actions-our-app-can-perform)
        * [Mapping state changes to location changes](#mapping-changes-in-the-app-state-to-a-possible-location-change)
    * [Preventing circularity](#preventing-circularity)
    * [Normalizing location changes](#normalizing-location-changes)
* [Relationship with other modules](#relationship-with-other-modules)
    * [elm-router](#relationship-with-elm-router)
    * [start-app](#relationship-with-start-app)
* [API](#api)
    * [Configuration](#configuration)
        * [`start : Config model action -> Signal (Task () ())`](#start)
        * [`Config`](#config)
            * [`prefix : String`](#prefix)
            * [`models : Signal model`](#models)
            * [`delta2update : model -> model -> Maybe HashUpdate`](#delta2update)
            * [`location2action : List String -> List action`](#location2action)
            * [`address : Address action`](#address)
    * [Helpers for `HashUpdate`](#helpers-for-hashupdate)
        * [`set : List String -> HashUpdate`](#set)
        * [`replace : List String -> HashUpdate`](#replace)
        * [`apply : (List String -> List String) -> HashUpdate -> HashUpdate`](#apply)
        * [`map : (List String -> List String) -> Maybe HashUpdate -> Maybe HashUpdate`](#map)
        * [`extract : HashUpdate -> List String`](#extract)
* [Implementing the API](#implementing-the-api)
    * [Implementing `delta2update`](#implementing-delta2update)
    * [Implementing `location2action`](#implementing-location2action)
* [The Signal Graph](#what-this-module-does-to-the-signal-graph)
* [Example Code](#example-code)


## Overview

Before turning to the actual API, here's an overview of the thinking behind the
module.


### Routing

What does "routing" mean? Essentially, there are two things which we want to
do:

* Map changes in the browser's location to actions our app can perform.
* Map changes in our app's state to changes in the browser's location.

Now, the changes in the browser's location that we are particularly interested
in are changes to the hash -- that is, the portion of the URL following the
"#".  It is that kind of change which leaves us on the same page -- the "single
page app". So, we can make the state of our app bookmarkable (at least in
part), and we can make the "back" and "forward" buttons work (at least to some
degree), without having to reload the page from the server.

A few notes in passing:

*   This module currently ignores everything before the hash. If you've got a
    reason to want to take that into account, let me know and perhaps we can
    figure out a good way to fit it in.

*   This module doesn't do anything fancy with the html5 History API. For
    instance, it only uses the visible URL -- it doesn't try to push and pop
    custom JSON state.

*   As a consequence of that, the visible URL does actually have to have a "#"
    in it.

So, let's think a little more about the two mappings we identified above.


#### Mapping location changes to actions our app can perform

In effect, what we're looking for here is (conceptually) something like this
(in pseudo-code):

```elm
History.hash -> Signal (List action)
```

That is, when the location hash changes (whether because of manually typing in
the location bar, activating a bookmark, or using the 'forward' and 'back'
buttons, etc.), we want to convert that into actions which our app can perform.

You might wonder why we map the location change to actions, rather than a
state? I did originally try mapping the location change to a state. However, if
you do that, you still need to have an action to actually set that state.  Yet,
normally I don't want to have a "big" `SetState Model` action -- that is too
coarse-grained. Futhermore, it's unlikely that your **entire** state is encoded
in the URL. So, really what the location change is doing is changing some part
of your state -- i.e., it corresponds to an action.

Of course, if you'd prefer to think in terms of state alone, you could always
define a `SetState Model` action and map the location change to that.

Another possibility I considered was mapping the location change to a `Task`.
This is, in fact, what the module does internally -- once it has the actions,
it creates a `Task` consisting of sending the actions to an `Address action`
that you have supplied. This seemed like it would be a convenience for the
usual pattern.  However, if you come across a case in which it would be useful
to map location changes to a more arbitrary `Task`, we could consider an
alternate API for that.


#### Mapping changes in the app state to a possible location change

Here, what we are looking for (conceptually) is something like this (in
pseudo-code):

    Signal model -> Signal (Maybe HashUpdate)

That is, when your app's model changes, we want to possibly generate a change
to the location hash. Now, there are a couple of things worth noting about
this.

*   Of course, not every change to the model will imply a change to the
    location -- sometimes the model changes but the location stays the same.
    That is why, conceptually, it is a `Maybe HashUpdate`.

*   There are two kinds of `HashUpdate` you might want to make. You might want
    to change the location **and** create a new history entry. Or, you might
    want to change the location **without** making a new history entry. (For
    instance, you might want the location to track what the user is typing in a
    search form, but you might not want to create a new history entry for every
    character typed).

One question you might ask is this: why are changes to the location triggered
by changes to the model, rather than by actions? That is, might it be better to
conceive of what we want here as this instead:

    Signal action -> Signal (Maybe HashUpdate)

In fact, it might be interesting to try that. However, you would, of course, in
some cases need access to the whole model (not just the action) in order to
construct the appropriate hash. Now, there is a point at which you have access
to the action and the model -- that is, inside your `update` function. You
could, in fact, think of the `HashUpdate` as being just another kind of effect
that the `update` function arranges to be performed -- indeed, it is a kind
of effect.

However, there are disadvantages in forcing you to address yet another concern
in your `update` function. By generating the `HashUpdate` from changes to the
model, rather than from actions, we can intervene in the signal graph after the
fact, so to speak. That is, whatever your app does to change the model, we can
pick up on that without having to intrude into the `update` function itself.
So, this approach feels more modular. However, it is by no means the only way
it could be done.


### Preventing circularity

The quick-witted amongst you may have noticed that there is a potential
circularity in the two things which this module is trying to do -- that is:

* mapping location changes to actions your app can perform; and
* mapping model changes to changes in location

After all, actions your app performs will typically change the model, which
in turn will cause a location change, which in turn will ... well, you
see the problem.

This module deals with the potential circularity in a couple of ways:

*   Before we actually change the location, we check to see whether the new
    location is equal to the current location. If so, we do nothing,
    since changing the location would be a no-op (and yet would trigger an
    unwanted reaction).

*   Before we react to a location change, we check to see if the new location
    is equal to the last location which we set. If so, we do nothing, since
    there is no need to react to a location change that we initiated.

*   While we are performing actions in response to a location change, we
    disable the detection of model changes.


### Normalizing location changes

This module essentially conceives of a location change as a `List String`
which it normalizes when transitioning to and from the actual location.
It's probably worth explaining how this normalization works.

When the module sees a change in the location hash, what it sees is a
string which looks something like this:

    "#!/somedata/following/the%20hash"

Now, before this gets supplied to your code, it is normalized to a `List
String` in the following manner:

*   First, we remove a prefix. The default prefix is "#!/", but you can
    configure that if you prefer a different scheme. (The first character of
    the prefix would normally need to be a "#", though). The purpose of the
    prefix is to help distinguish these "special" URLs from other uses of a URL
    hash.

    So, in this example, we'd be left with `"somedata/following/the%20hash"`

*   Then, we split the string, using "/" as a delimiter. So, in the example,
    we'd now have `["somedata", "following", "the%20hash"]`

*   Finally, each element in the list would be uriDecoded. So, we'd end up
    with `["somedata", "following", "the hash"]`

So that is what your code would ultimately be supplied with, when given
a `List String`.

The reverse process occurs when your code supplies a `List String` in order
to construct a `HashUpdate`. In other words, if you supply:

    `["somedata", "following", "the hash"]`

then the module normalizes it as follows:

*   First, we uriEncode the parts of the list, which gives us `["somedata",
    "following", "the%20hash"]`.

*   Then, we join the list with a "/", giving us `"somedata/following/the%20hash"`

*   Finally, we prepend the same prefix (again, by default "#!/"). So, in this
    example, we'd be left with `"#!/somedata/following/the%20hash"`

So, that is what the location would ultimately be set to, when you provide
a `List String` to construct a `HashUpdate`.


## Relationship with other modules

Before turning to the API itself, there are a few things you might find
useful to know about the relationship between elm-route-hash and a few
other modules.


### Relationship with elm-router

There is another Elm module which addresses routing,
[elm-router](https://github.com/TheSeamau5/elm-router). That module is focused
on the following concern: given a `String` (from whatever source, but
conceptually a URL or part of a URL), how can we convert that `String` to
something we can use, whether that is `Html`, or, more indirectly, an action or
model (the elm-router module itself doesn't care).

So, if we think about the two conceptual "mappings" that this module is
interested in, elm-router is relevant to one of them -- that is, to the mapping
from

    History.hash -> Signal (List action)

When we get to the actual API (in a moment, I promise!), you'll see that this
module asks you for a `location2action` function to help do that. That is, this
module asks you to provide a function of the form:

    List String -> List action

So, in principle, you could use elm-router to help with constructing that
function.  Now, elm-router expects the input to be a `String`, whereas this
module divides the `String` into a `List String` using "/" as a delimiter.
However, you could easily turn the `List String` back into a `String` via
`String.join`.

Thus, you could conceivably use elm-router as part of your strategy for
supplying the `location2action` function that this module needs. However, you
don't have to use it -- I'll mention some alternative ways to implement
`location2action` below.

### Relationship with start-app

As you'll see in a moment (honestly!), you need to provide a `Signal model`
and an `Address action` to configure this module -- that is, you need to tell
this module what your signal of models is, and you need to provide an address
where we can send actions.

If you're using [evancz/start-app](https://github.com/evancz/start-app) to 
structure your app, then you're going to run into a difficulty here, because
start-app doesn't export the `Address action`. That is, it constructs and
uses an `Address action` internally, but it's not exported, so you can't
supply it to this module.

Now, start-app does allow you to provide a `List (Signal Action)` to its
`start` function, which in principle we could use to feed actions into the app.
However, that approach seems to have a chicken-and-egg problem. In order to
create the `Signal action`, we need the `Signal model` as an input.  However,
we can only get the `Signal model` from start-app as a **result** of running
start-app's `start` function. So, we need the results of `StartApp.start`
before we call it, which is tough to arrange.

But, it turns out to be possible. I used to think that using elm-route-hash
with `StartApp` required you to make some local modifications to `StartApp`.
However, there is a way to avoid that, by creating an intermediate mailbox.
Here's what you would do.

```elm
{- In your `Main` module, create a mailbox for your action type ... something
like this. Of course, the exact details depend on your `Action` type. Note that
you'll typically need to define a `NoOp` action in order to fulfill the
requirement for signals to have an initial value.
-}
messages : Signal.Mailbox Action
messages =
    Signal.mailbox NoOp


{- Then, when you call `StartApp.start`, supply the mailbox's signal as an
input -- something like this (your details may vary).
-}
app : App Model
app =
    StartApp.start
        { init = init
        , update = update
        , view = view
        , inputs = [ messages.signal ]
        }


{- And, when you call `RouteHash.start`, supply the mailbox's address --
something like this (again, your details may vary).
-}
port routeTasks : Signal (Task () ())
port routeTasks =
    RouteHash.start
        { prefix = RouteHash.defaultPrefix
        , address = messages.address
        , models = app.model
        , delta2update = ExampleViewer.delta2update
        , location2action = ExampleViewer.location2action
        }

```

So, it turns out that using elm-route-hash with `StartApp` is not as painful
as I originally thought.


## API

See, I promised I would get to the API eventually!


### Configuration

#### start

To use this module, you need to call the `start` function,
which looks like this:

    start : Config model action -> Signal (Task () ())

The signal of tasks returned by this function needs to be sent to a port
to be executed. So, you might call it in your main module something
like this:

    port routeTasks : Signal (Task () ())
    port routeTasks =
        RouteHash.start
            { prefix = RouteHash.defaultPrefix
            , models = models
            , delta2update = delta2update 
            , address = address
            , location2action = location2action
            }


#### Config

You will note that the single parameter is of type 
`Config`, which is a record type defined as follows:

    type alias Config model action =
        { prefix : String
        , models : Signal model
        , delta2update : model -> model -> Maybe HashUpdate
        , location2action : List String -> List action
        , address : Address action
        }

Here is the significance of each of the fields in the `Config` record.

##### prefix 

    prefix : String

The initial characters that should be stripped from the hash (if present)
when reacting to location changes, and added to the hash when generating
location changes. Normally, you'll likely want to use `defaultPrefix`,
which is "#!/".

##### models

    models : Signal model

Your signal of models. This is required so that we can react to changes in
the model, possibly updating the location.

##### delta2update

    delta2update : model -> model -> Maybe HashUpdate

A function which takes two arguments and possibly returns a `HashUpdate`.
The first argument is the previous model. The second argument is the current
model.

The reason you are provided with both the previous and current models is
that sometimes the nature of the location update depends on the difference
between the two, not just on the latest model. For instance, if the user is
typing in a form, you might want to use `replace` rather than `set`. Of
course, in cases where you only need to consult the current model, you can
ignore the first parameter.

See [further comments](#implementing-delta2update) on implementing
`delta2update` below.

##### location2action

    location2action : List String -> List action

A function which takes a `List String` and returns actions your app can
perform. 

Essentially, your `location2action` should return actions that are the
reverse of what your `delta2update` function produced. That is, the `List
String` you get back in `location2action` is the `List String` that your
`delta2update` used to create a `HashUpdate`. So, however you encoded your
state in `delta2update`, you now need to interpret that in `location2action`
in order to return actions which will produce the desired state.

Note that we disable `delta2update` while we perform the actions that you
return from `location2action`. This helps prevent infinite loops -- you
don't have to worry that your actions will trigger further location changes,
thus triggering further actions ...

See [further comments](#implementing-location2action) on implementing
`location2action` below.

##### address

    address : Address action

A `Signal.Address` to which the actions returned by `location2action` can
be sent.


### Helpers for `HashUpdate`

There are a number of functions which exist to help you produce and modify
`HashUpdate` objects.

#### set

    set : List String -> HashUpdate

Returns a `HashUpdate` that will update the browser's location, creating
a new history entry.

The `List String` represents the hash portion of the location. Each element
of the list will be uriEncoded, and then the list will be joined using
slashes ("/"). Finally, a prefix will be applied (by default, "#!/", but it
is configurable).

#### replace

    replace : List String -> HashUpdate

Returns a `HashUpdate` that will update the browser's location, replacing
the current history entry.

The `List String` represents the hash portion of the location. Each element of
the list will be uriEncoded, and then the list will be joined using slashes
("/"). Finally, a prefix will be applied (by default, "#!/", but it is
configurable).

#### apply

    apply : (List String -> List String) -> HashUpdate -> HashUpdate

Applies the supplied function to the `List String` inside the `HashUpdate`.

#### map

    map : (List String -> List String) -> Maybe HashUpdate -> Maybe HashUpdate

Applies the supplied function to the `List String` inside the `HashUpdate`.

You might use this function when dispatching in a modular application.
For instance, your `delta2update` function might look something like this:

    delta2update : Model -> Model -> Maybe HashUpdate
    delta2update old new =
        case new.virtualPage of
            PageTag1 ->
                RouteHash.map ((::) "page-tag-1") PageModule1.delta2update old new

            PageTag2 ->
                RouteHash.map ((::) "page-tag-2") PageModule2.delta2update old new

Of course, your model and modules may be set up differently. However you do it,
the `map` function allows you to dispatch `delta2update` to a lower-level module,
and then modify the `Maybe HashUpdate` which it returns.

#### extract

    extract : HashUpdate -> List String

Extracts the `List String` from the `HashUpdate`.


## Implementing the API

Now, you may have noticed that you basically need to supply two significant
functions in order to use this module: `delta2update` and `location2action`.
So, it might be useful to comment a little further on how you might go about
implementing those functions.


### Implementing `delta2update`

What you need to do in your `delta2update` function is take your current (and
previous) state, and derive a `List String` that represents what the location
hash should be (remembering the normalization which this module will apply).
Once you have the `List String` you can call `set` or `replace` to produce a
`HashUpdate`.

Now, in order for this to work, there must be something in your model that
keeps track of what we might call the 'virtual page' or the 'focus' or the
'view model' -- that is, something which tells you what the user is currently
looking at.

So, the job of `delta2update` is to translate whatever that is into a `List
String`. Now, you can keep as much or as little of the state in the URL as you
like. You'll basically get the `List String` back in your `location2action`
function, so it's up to you to decide how to encode some of your state into a
`List String`, and how to decode the `List String` once you get it back.

Part of the purpose of using a `List String` is to help with a modular approach
to routing. For instance, suppose one has a top-level field in the model called
`virtualPage` which tracks which virtual page the user is looking at. One
could then dispatch based on that field to one sub-module or another. Then,
once the sub-module has returned, you can prepend something to the beginning of
the list. That way, the sub-module only has to worry about encoding its own
state -- the higher-level module will add something that discriminates between
one sub-module and another. For example:

    delta2update : Model -> Model -> Maybe HashUpdate
    delta2update old new =
        case new.virtualPage of
            PageTag1 ->
                RouteHash.map ((::) "page-tag-1") PageModule1.delta2update old new

            PageTag2 ->
                RouteHash.map ((::) "page-tag-2") PageModule2.delta2update old new

Now, what might the sub-module's `delta2update` look like? In some cases, you
might not actually need to record any state at the sub-module level ... perhaps
it is sufficient that the super-module will dispatch to the sub-module at all.
In that case, you might use something like:

    delta2update : Model -> Model -> Maybe HashUpdate
    delta2update old new =
        Just <| RouteHash.set []

That is, you might use just an empty list (to which the super-module can then
prepend something). 

Suppose, though, that the sub-module has some state you'd like to encode.
Imagine, for instance, that the submodule presents a search field, and you'd
like the search term to be reflected in the URL, so that the 'forward'
and 'back' buttons work as expected. You might do something like this
in the sub-module:

    delta2update : Model -> Model -> Maybe HashUpdate
    delta2update old new =
        Just <| RouteHash.replace [new.searchForm.searchField]

Note that you might want to do something different depending on what the
previous state was (for instance, you might want to switch between using `set`
and `replace` to construct the `HashUpdate`). 

Of course, various details about how you handle modularity in your app will
differ. The essential point is that you need to build up a `HashUpdate` by
dispatching based on the new (and possibly old, if relevant) models.


### Implementing `location2action`

The `List String` you get in your `location2action` function is basically the
`List String` that you generated when you created a `HashUpdate` in
`delta2update`. So, the general idea is that you need to reverse that work iin
`location2action` -- that is, you need to decode the strings and produce
whatever actions will create the state they represent.

While `location2action` returns a `List action`, it may often just be a list
with a single action. The reason a `List action` is allowed is to make it
easier, in a modular application, for super-modules and sub-modules to both
provide an action.

Given the example `delta2update` functions above, how might we write the
equivalent `location2action` functions? For the super-module, it might
look like this (assuming the existence of the named actions):

    location2action : List String -> List Action
    location2action list =
        case list of
            first :: rest ->
                case first of
                    "page-tag-1" ->
                        List.map ShowPage1 (PageModule1.location2action rest)

                    "page-tag-2" ->
                        List.map ShowPage2 (PageModule2.location2action rest)

            _ ->
                [ShowErrorPage]

That is, the super-module might "consume" the first element of the list,
and dispatch to one submodule or another based on it. Then, after getting
back the `List action` from the submodule, the super-module would tag
those actions to convert them to its own action type. (And the super-module
could add its own action to the list, if there was any interesting information
encoded in the super-module's portion of the hash).

What, then, might the submodule implementation look like? If the submodule
doesn't really encode anything in `delta2update`, then it would probably
have a default action ... perhaps something like this (assuming the
existence of a `ShowPage` action):

    location2action : List String -> List Action
    location2action list = [ShowPage]

In this case, it's enough that the super-module has selected the sub-module ...
the sub-module always generates the same action.

Now, suppose the submodule actually has encoded some state in the URL.
Consider, for instance, the search field example given above. That might
be implemented like this (again, assuming the relevant actions exist):

    location2action : List String -> List Action
    location2action list =
        case list of
            first :: rest ->
                [SetSearchField first]

            _ ->
                [ShowPage]


## What this module does to the signal graph

You may find it useful to know what [`start`](#start) does to the signal graph.
In these matters, a picture is worth a thousand words, so here's a picture.

![Signal graph](https://cdn.rawgit.com/rgrempel/elm-route-hash/master/signals.svg)


## Example Code

In order to illustrate how to use elm-route-hash, I though it might be useful
to take some familiar code and show how to turn it into a single-page app with
bookmarkable URLs and a working "forward" and "back" button.

What code could be more familiar than the
[Elm Architecture Tutorial](https://github.com/evancz/elm-architecture-tutorial)?
And, the tutorial consists of 8 examples which are each separate pages. So, why
not show how to turn those 8 examples into a single page?

Here's a [link to the example](https://github.com/rgrempel/elm-route-hash/tree/master/examples/elm-architecture-tutorial).
