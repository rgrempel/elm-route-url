# elm-route-url

This is a module for routing single-page-apps in Elm, building on the
[`elm-lang/navigation`](http://package.elm-lang.org/packages/elm-lang/navigation/latest)
package. It is the successor to elm-route-hash:

* now compatible with Elm 0.18, and

* no longer limited to working only with the hash (hence the name change).


## Rationale

Essentially, elm-route-url helps you to keep the URL displayed in the browser's
location bar in sync with the state of your app. As your app changes state, the
displayed URL changes to match. If the user changes the URL (through a
bookmark, the back/forward button, or typing in the location bar), then your
app changes state to match.

So, there are two things going on here:

* Mapping changes in our app's state to changes in the browser's location.
* Mapping changes in the browser's location to changes in our app's state.

Now, you can already arrange for these things to happen using
[`elm-lang/navigation`](http://package.elm-lang.org/packages/elm-lang/navigation/latest).
Furthermore, there are already a wealth of complementary packages,
such as:

* [evancz/url-parser](http://package.elm-lang.org/packages/evancz/url-parser/latest)
* [Bogdanp/elm-combine](http://package.elm-lang.org/packages/Bogdanp/elm-combine/latest)
* [Bogdanp/elm-route](http://package.elm-lang.org/packages/Bogdanp/elm-route/latest)
* [etaque/elm-route-parser](http://package.elm-lang.org/packages/etaque/elm-route-parser/latest)
* [poyang/elm-router](http://package.elm-lang.org/packages/poying/elm-router/latest)
* [sporto/erl](http://package.elm-lang.org/packages/sporto/erl/latest)
* [sporto/hop](http://package.elm-lang.org/packages/sporto/hop/latest)

So, what does elm-route-url do differently than the others?


### Mapping changes in the app state to a possible location change

If you were using [`elm-lang/navigation`](http://package.elm-lang.org/packages/elm-lang/navigation/latest)
directly, then you would make changes to the URL with ordinary commands.
So, as you write your `update` function, you would possibly return a command,
using [`modifyUrl`](http://package.elm-lang.org/packages/elm-lang/navigation/1.0.0/Navigation#modifyUrl)
or [`newUrl`](http://package.elm-lang.org/packages/elm-lang/navigation/1.0.0/Navigation#newUrl).

Now, you can make this work, of course. However, the `update` function isn't
really the perfect place to do this. Your update function looks like this:

```elm
update : Message -> Model -> (Model, Cmd Message)
```

But you don't really need to know the `Message` in order to compute a new URL
for the location bar. After all, it doesn't matter how you got there -- all you
want to ensure is that the URL reflects the final state of your model. (For
instance, consider a module with an `Increment` message and a `Decrement`
message. The URL doesn't care which way you arrived at a particular state).

So, elm-route-url asks you to implement a function with a different signature:

```elm
delta2url : Model -> Model -> Maybe UrlChange
```

What you get is the previous model and the new model. What you're asked to produce
is possibly a change to the URL. (The reason you get both the old and new model
is because sometimes it helps you decide whether to create a new history entry,
or just replace the old one).

There are a couple of possible advantages to this way of doing things:

* Less clutter in your `update` function.

* You just calculate the appropriate URL, given the state of your app.
  elm-route-url automatically avoids creating a new history entry if the
  URL hasn't changed.

* elm-route-url also automatically avoids an infinite loop if the change in the
  app's state was already the *result* of a URL change.

Of course, you can solve those issues with your own code. However, if you
use elm-route-url, you don't have to.


### Mapping location changes to messages our app can respond to

If you use the official [navigation](http://package.elm-lang.org/packages/elm-lang/navigation/latest)
package in Elm 0.18 directly, the `Navgation.program` differs from the
standard `Html.program` in two ways:

First, you are asked to implement an argument
to `Navigation.program` that converts a `Location` to a message
whenever the URL changes.

Second, the `Navigation.program` takes an init function that
takes a `Location` as an argument. This lets you use the URL on the first frame.

In elm-route-url, this functionality for both of these is handled by asking
you to implement a function with a different signature:

```elm
location2messages : Location -> List Message
```

`location2messages` will be called when the underlying `Navigation.program`
`init` method is invoked, so you don't need to change that in your
program's code. And of course `location2messages` will also be called every
time the location is changed externally (not from a state change that
generated a new location via `delta2url`).


## API

For the detailed API, see the documentation for `RouteUrl` and `RouteHash`
(there are links to the right, if you're looking at the Elm package site).

The `RouteUrl` module is now the "primary" module. It gives you access to the
whole `Location` object, and allows you to use the path, query and/or hash, as
you wish.

The main thing that elm-route-url handles is making sure that your
`location2messages` and `delta2url` functions are called at the appropriate
moment. How you parse the `Location` (and construct a `UrlChange`) is pretty
much up to you. Now, I have included a `RouteUrl.Builder` module that could
help with those tasks. However, you don't need to use it -- many other
approaches would be possible, and there are links to helpful packages above.

The `RouteHash` module attempts to match the old API of elm-route-hash as
closely as possible. You should be able to re-use your old `delta2update` and
`location2action` functions without any changes. What will need to change is
the code in your `main` module that initializes your app. The `RouteHash`
module will probably be removed in a future version of elm-route-url, so you
should migrate to using `RouteUrl` at an appropriate moment.


## Examples

I've included [example code](https://github.com/rgrempel/elm-route-hash/tree/master/examples/elm-architecture-tutorial)
which turns the old Elm Architecture Tutorial (upgraded to Elm 0.18) into
a single-page app. I've included three variations:

* Using the new `RouteUrl` API with the full path.
* Using the new `RouteUrl` API with the hash only.
* Using the old `RouteHash` API.

Note that the example code makes heavy use of the `RouteUrl.Builder` module.
However, as noted above, you don't necessarily need to use that -- a variety
of alternative approaches are possible.
