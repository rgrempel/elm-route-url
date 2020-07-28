# elm-route-url

This is a module for routing single-page-apps in Elm, building on the
[`elm/browser`](https://package.elm-lang.org/packages/elm/browser/latest)
package.

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
[`elm/browser`](http://package.elm-lang.org/packages/elm/browser/latest).
So, what does elm-route-url do differently than the others? First, I'll
address this practically, then philosophically.


### Mapping changes in the app state to a possible location change

If you were using [`elm/browser`](https://package.elm-lang.org/packages/elm/browser/latest)
directly, then you would make changes to the URL with ordinary commands.
So, as you write your `update` function, you would possibly return a command,
using [`replaceUrl`](https://package.elm-lang.org/packages/elm/browser/latest/Browser-Navigation#replaceUrl)
or [`pushUrl`](https://package.elm-lang.org/packages/elm/browser/latest/Browser-Navigation#pushUrl).

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

Furthermore, every state of your model really ought to correspond with some URL.
That is, given some state of your model, there must be something that you'd like
to have appear in the URL. Or, to put it another way, what appears in the URL
really ought to be a function of your state, not the last message you received.

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

If you use the official [browser](https://package.elm-lang.org/packages/elm/browser/latest/)
package in Elm 0.19 directly, you react to location changes by providing
two arguments to `Browser.application`: `onUrlRequest`, which converts a
`UrlRequest` to a message your app can use to decide whether to permit the
requested URL change; and `onUrlChange`, which converts a new `Url` to a
message your app can deal with. Those messages are then fed into your
`update` function as the `Url` changes.

On the surface, elm-route-url works in a similar manner, except that it
asks you to implement a function which returns a list of messages.
(This is possibly a convenience when you need multiple messages to
react to the URL change, though of course you could also redesign your
app to do multiple things with a single message).

```elm
location2messages : Location -> List Message
```

`location2messages` will also be called when your `init` function is invoked,
so you will also get access to the very first `Location`.

So, that is similar to how `Browser` works. The difference is that
`Browser` will send you a message even when you programmatically change
the URL. By contrast, elm-route-url only sends you messsages for **external**
changes to the URL -- for instance, the user clicking on a link, opening
a bookmark, or typing in the address bar. You won't get a message when you've
made a change in the URL due to your `delta2url` function, since your state
is already in sync with that URL -- no message is required.


### Philosphically

You can, if you are so inclined, think about those differences in a more
philosophical way. There is a [thread](https://groups.google.com/forum/#!topic/elm-discuss/KacB1VqkVJg/discussion)
on the Elm mailing list where Erik Lott gives an excellent summary.
The question, he says, is whether the address bar should drive the model,
or whether the model should drive the address bar. For more details,
read the thread -- it really is a very good summary.

Another nice discussion of the philosophy behind elm-route-url is in a blog post
by Amitai Burstein, under the heading
[URL Change is not Routing](http://www.gizra.com/content/thinking-choosing-elm/#url-change-is-not-routing)


## API

For the detailed API, see the documentation for `RouteUrl` (there's a link to
the right, if you're looking at the Elm package site).

The main thing that elm-route-url handles is making sure that your
`location2messages` and `delta2url` functions are called at the appropriate
moment. How you parse the `Url` (and construct a `UrlChange`) is pretty
much up to you. You can use [`elm/url`](https://package.elm-lang.org/packages/elm/url/latest/)
to help with those tasks.


## Examples

I've included [example code](https://github.com/rgrempel/elm-route-hash/tree/master/examples/elm-architecture-tutorial)
which turns the old Elm Architecture Tutorial (upgraded to Elm 0.19) into
a single-page app. I've included two variations:

* Using the `RouteUrl` API with the full path.
* Using the `RouteUrl` API with the hash only.