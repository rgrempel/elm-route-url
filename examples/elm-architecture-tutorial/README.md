# The Elm Architecture Tutorial as a single page app

In order to illustrate how to use
[elm-route-hash](https://github.com/rgrempel/elm-route-hash),
I though it might be useful to take some familiar code and show
how to turn it into a single-page app with bookmarkable URLs
and a working "forward" and "back" button.

What code could be more familiar than the
[Elm Architecture Tutorial](https://github.com/evancz/elm-architecture-tutorial)?
And, the tutorial consists of 8 examples which are each separate pages. So, why
not show how to turn those 8 examples into a single page?

So, what steps did I follow to do this?

## Clean up the original code

*   I copied the 8 examples from the Elm Architecture Tutorial.

*   I renamed the directories to "Example1", "Example2" etc., instead of "1",
    "2", etc., since that made for better module names. (Since all examples
    will now be in a single page, the directory names are part of the module
    name).

*   Then, I changed the module declarations in each file to include the
    directory name. For instance, the declaration of `Counter.elm` in the first
    example changes from `module Counter where` to `module Example1.Counter
    where`. I made the equivalent changes to the existing `import` statements.

*   Then I removed the `README.md` and `elm-package.json` files
    from each example folder. They aren't necessary any longer, since all the
    examples will now be on a single page.

*   I copied `StartApp.elm` from
    [evancz/start-app](https://github.com/evancz/start-app.git), because it
    will be necessary to make a small modification to it in order to use it
    with elm-route-hash.

*   I created an `elm-package.json` file at the root of the project.

*   I moved the `assets` directory from each example folder to the root of the
    project.

*   And I created this README -- the very one you are reading right now.

So, none of these were actual code changes -- I just cleaned things up so that
the real work could start.

Note that I hadn't yet removed the individual `Main.elm` files from each example,
because they contain just a little bit of code that needs to be accounted for.
Ultimately, we won't want individual `Main.elm` files, of course.


## Create the ExampleViewer

Now, to create a single-page app, we'll need something which is aware of all the
potential examples, tracks which one we're looking at, and allows some way
to switch from one to another. Let's call that an `ExampleViewer` ... I've
implemented it in `ExampleViewer.elm`. To see what it does, it's probably
best just to look at the code.

This also required some minor changes in the examples themselves.

So, at this stage, we have turned the 8 separate example pages into a single
page app that allows us to navigate from one example to another by clicking.
But, we haven't done anything with the URL yet -- the next step is to actually
hook up elm-route-hash.


## Basic use of elm-route-hash

So, the next step is to do a basic implementation of elm-route-hash. What
does this involve?

*   Our `ExampleViewer.elm` needs to implement `delta2update` and
    `location2action`.

*   Our `Main.elm` needs to call `RouteHash.start`

*   We need to make a small modification to start-app, to expose the
    `Address` to which we can send actions.

To see how I did this, the best thing is to read the code.

So, what do we have now?

*   Try navigating with the links to each example (like we could do
    at the previous stage). Notice how the URL in the location bar
    changes.

*   After navigating with the links, try using the 'forward' and
    'back' buttons -- see what they do.

*   Navigate to an example, and then hit 'Reload' in the browser
    -- see if something good happens.

*   Try bookmarking one of the examples. Navigate somewhere else,
    and then activate the bookmark.

Isn't this fun? And it wasn't really that hard to do.

