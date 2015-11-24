module History where
{-| Elm bindings to HTML5 History API.

# Changing the URL path
@docs setPath, replacePath

# Going back and forth in the browser history
@docs back, forward, go

# URL path as input
@docs path, hash, length

-}

import Signal
import Task exposing (Task)

import Native.History

{-| Sets the path of the url to the given path.
If you are familiar with the HTML5 History API,
`setPath` calls `history.pushState()` which means
that in performing this task, the browser history
moves forward. In other words, pressing the back
button will lead you where you were prior to performing
this task.

    setPath "/blog.html"
-}
setPath : String -> Task error ()
setPath = Native.History.setPath


{-| Replaces the path of the url by the given path.
If you are familiar with the HTML5 History API,
`replacePath` calls `history.replaceState()` which means
that in performing this task, the browser history
does not move forward. In other words, pressing the back
button will not lead you to where you were prior to
performing this task. This is useful for things such as
slideshows of login pages where the paths are transient
and you do not wish to clutter the back button. If you
want to simply point users towards a different page,
consider using `setPath`.
-}
replacePath : String -> Task error ()
replacePath = Native.History.replacePath


{-| Move backwards or forwards in the browser history
by the given amount. If given a positive number, `go`
will move the browser history forward by that amount.
If given a negative number, `go` will move the browser
history back by the absolute value of that amount. This
results in a no-op if there are no available pages to
go to in the browser history.
-}
go : Int -> Task error ()
go = Native.History.go


{-| Moves the browser history back by 1. Equivalent
to pressing the back button on the browser or calling
`go -1`.
-}
back : Task error ()
back = Native.History.back

{-| Moves the browser history forward by 1. Equivalent
to pressing the forward button on the browser or calling
`go 1`.
-}
forward : Task error ()
forward = Native.History.forward

{-| The length of the browser history. This number does not
state where you are in relation to the browser history but
simply how long that history is.
-}
length : Signal Int
length = Native.History.length

{-| The current hash value of the url. The value is updated
whenever it is changed, usually through interaction.
When you click on an `a` tag, the browser focuses on the area
around the tag and does not refresh the page. This change is
mirrored in the url where often a `#` is added. It is often
useful to track these changes and perform different operations
depending on the state of the hash.

Hashes are of the form: `#myTag`
-}
hash : Signal String
hash = Native.History.hash

{-| The current path value of the url. The value is updated
whenever it is changed, either through interaction or code.
This is the main way you can create single page applications.
By incorporating the `path` as an input of your application,
you are able to react to changes to these paths and route
and re-route your pages accordingly in order to show the most
appropriate information given the path.

Paths are of the form: `/myPath.html` or `/users/4873/profile.html`
-}
path : Signal String
path = Native.History.path
