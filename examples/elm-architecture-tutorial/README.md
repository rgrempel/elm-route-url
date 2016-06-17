# The Elm Architecture Tutorial as a single page app

In order to illustrate how to use
[elm-route-url](https://github.com/rgrempel/elm-route-url), I though it might
be useful to take some familiar code and show how to turn it into a single-page
app with bookmarkable URLs and a working "forward" and "back" button.

What code could be more familiar than the
[Elm Architecture Tutorial](https://github.com/evancz/elm-architecture-tutorial)?
And, the tutorial consists of 8 examples which are each separate pages. So, why
not show how to turn those 8 examples into a single page?


## An ExampleViewer

Now, to create a single-page app, we'll need something which is aware of all the
potential examples, tracks which one we're looking at, and allows some way
to switch from one to another. Let's call that an `ExampleViewer` ... I've
implemented it in `ExampleViewer.elm`. To see what it does, it's probably
best just to
[look at the code](https://github.com/rgrempel/elm-route-url/blob/master/examples/elm-architecture-tutorial/ExampleViewer.elm).

You'll see near the end of the `ExampleViewer` code that I've implemented
examples for the old `RouteHash` API, as well as the new `RouteUrl` API,
either using the full URL or just the hash.

Here are some things you can try:

*   Try navigating with the links to each example. Notice how the URL in the
    location bar changes.

*   After navigating with the links, try using the 'forward' and 'back' buttons
    -- see what they do.

*   Navigate to an example, and then hit 'Reload' in the browser -- see if
    something good happens.

*   Try bookmarking one of the examples. Navigate somewhere else, and then
    activate the bookmark.

I have also set up some more advanced things, tracking not just which example
we're looking at, but some additional state specific to each example.

How much of this you want to do is entirely up to you. Generally speaking, you
should only track "view model" state in the URL -- that is, state which affects
how the data appears to the user, rather than state which is part of the
fundamental, permanent data of your app. Otherwise, the back and forward
buttons, bookmarks, etc., will do unexpected things.  I suppose the distinction
here is like the distinction between "GET" requests and "POST" or "PUT"
requests in HTTP. Changing the URL is analogous to a "GET" request, and thus
should not change fundamental state -- it should only change state that affects
something about which part of the app the user is viewing at the moment.

So, depending on how you conceive of that, there isn't necessarily a lot more
in the examples that really qualifies as "view model" state. But, I did
illustrate how to do multiple layers of state anyway, just so you can see how.

*   Try incrementing an decrementing a counter in Example 1. Look at how the
    URL changes. Try the forward and back buttons. Try bookmarking and
    activating a bookmark. Try reloading a page. In the previous example,
    the examples would reset, whereas now they should maintain state.

*   Try playing with the other examples. I've hooked up most of the state
    with the URL -- it's actually a bit more than I might do in a real app.

I hope that helps get you started.


## Running the code

Here are links to three variations that you can try out live.

* the [old API](http://rgrempel.github.io/elm-route-url/examples/elm-architecture-tutorial/old-api.html) from elm-route-hash (`MainWithOldAPI.elm`)
* the new API, using the [full URL](http://rgrempel.github.io/elm-route-url/examples/elm-architecture-tutorial/full-url.html) (`MainWithFullUrl.elm`)
* the new API, using the [hash only](http://rgrempel.github.io/elm-route-url/examples/elm-architecture-tutorial/just-hash.html) (`MainWithJustHash.elm`)

To run the code locally instead, start up `elm-reactor` in this directory. You
can then click on one of the .elm files mentioned above to see that variation
of the example.

Note that reloading and bookmarking doesn't work with the "full URL" example,
because that requires server-side support that I haven't implemented for
the example. (That is, you'd have to adopt a scheme for the full URLs so that
the server knows what actual page to send).
