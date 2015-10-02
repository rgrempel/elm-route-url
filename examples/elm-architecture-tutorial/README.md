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



