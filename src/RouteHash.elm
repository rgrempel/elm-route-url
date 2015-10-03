module RouteHash
    ( HashUpdate, set, replace, apply, map, extract 
    , Config, defaultPrefix, start
    ) where


{-| This module provides routing for single-page apps based on changes to the
hash portion of the browser's location. The routing happens in both directions
-- that is, changes to the browser's location hash are translated to actions
your app performs, and changes to your model are translated to changes in the
browser's location hash. The net effect is to make it possible for the 'back'
and 'forward' buttons in the browser to do useful things, and for the state of
your app to be partially bookmark-able.

To use this module, you will need to configure it using the [`start`](#start)
function, as described below.

There is [additional documentation](https://github.com/rgrempel/elm-route-hash)
available in the README in the Github repository.

# Configuration

@docs start, Config, defaultPrefix

# Helpers for `HashUpdate`

@docs HashUpdate, set, replace, apply, map, extract
-}


import String exposing (uncons, split)
import Http exposing (uriDecode, uriEncode)
import Signal exposing (Signal, Address, Mailbox, mailbox, send, merge, sampleOn)
import Signal.Extra exposing (passiveMap2, deltas)
import Task exposing (Task)
import History


{-| An opaque type which represents an update to the hash portion of the
browser's location.
-}
type HashUpdate 
    = SetPath (List String)
    | ReplacePath (List String)


{-| Returns a [`HashUpdate`](#HashUpdate) that will update the browser's
location, creating a new history entry.

The `List String` represents the hash portion of the location. Each element of
the list will be uriEncoded, and then the list will be joined using slashes
("/"). Finally, a prefix will be applied (by [default](#defaultPrefix), "#!/",
but it is configurable).
-}
set : List String -> HashUpdate
set = SetPath


{-| Returns a HashUpdate that will update the browser's location, replacing
the current history entry.

The `List String` represents the hash portion of the location. Each element of
the list will be uriEncoded, and then the list will be joined using slashes
("/"). Finally, a prefix will be applied (by [default](#defaultPrefix), "#!/",
but it is configurable).
-}
replace : List String -> HashUpdate
replace = ReplacePath


{-| Applies the supplied function to the [`HashUpdate`](#HashUpdate). -}
apply : (List String -> List String) -> HashUpdate -> HashUpdate
apply func update =
    case update of
        SetPath list ->
            SetPath (func list)

        ReplacePath list ->
            ReplacePath (func list)


{-| Applies the supplied function to the [`HashUpdate`](#HashUpdate).

You might use this function when dispatching in a modular application.
For instance, your [`delta2update`](#Config) function might look something like this:

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
-}
map : (List String -> List String) -> Maybe HashUpdate -> Maybe HashUpdate
map func update =
    Maybe.map (apply func) update
    

{-| Extracts the `List String` from the [`HashUpdate`](#HashUpdate). -}
extract : HashUpdate -> List String
extract action =
    case action of
        SetPath list ->
            list

        ReplacePath list ->
            list


{-| Represents the configuration necessary to use this module.

*  `prefix` is the initial characters that should be stripped from the hash (if
    present) when reacting to location changes, and added to the hash when
    generating location changes. Normally, you'll likely want to use
    [`defaultPrefix`](#defaultPrefix), which is "#!/".

*   `models` is your signal of models. This is required so that we can react to
    changes in the model, possibly updating the location.

*   `delta2update` is a function which takes two arguments and possibly
    returns a [`HashUpdate`](#HashUpdate). The first argument is the previous
    model.  The second argument is the current model.

    The reason you are provided with both the previous and current models is
    that sometimes the nature of the location update depends on the difference
    between the two, not just on the latest model. For instance, if the user is
    typing in a form, you might want to use [`replace`](#replace) rather than
    [`set`](#set). Of course, in cases where you only need to consult the
    current model, you can ignore the first parameter.

    This module will normalize the `List String` in the update in the following
    way before setting the actual location. It will:

    * uriEncode the strings
    * join them with "/"
    * add the `prefix` to the beginning

    In a modular application, you may well want to use [`map`](#map) after dispatching
    to a lower level -- see the example in the [`map` documentation](#map).

    Note that this module will automatically detect cases where you return
    a [`HashUpdate`](#HashUpdate) which would set the same location that is
    already set, and do nothing. Thus, you don't need to try to detect that
    yourself.

    The content of the individual strings is up to you ... essentially it
    should be something that your `location2action` function can deal with.

*   `location2action` is a function which takes a `List String` and returns
    a list of actions your app can perform.

    The argument is a normalized version of the hash portion of the location.
    First, the `prefix` is stripped from the hash, and then the result is
    converted to a `List String` by using '/' as a delimiter. Then, each
    `String` value is uriDecoded.

    Essentially, your `location2action` should return actions that are the
    reverse of what your `delta2update` function produced. That is, the
    `List String` you get back in `location2action` is the `List String` that
    your `delta2update` used to create a [`HashUpdate`](#HashUpdate). So,
    however you encoded your state in `delta2update`, you now need to interpret
    that in `location2action` in order to return actions which will produce the
    desired state.

    Note that the list of actions you return will often be a single action. It
    is a `List action` so that you can return multiple actions, if your app is
    modular in a way that requires multiple actions to produce the desired
    state.

*   `address` is a `Signal.Address` to which the actions returned by
    `location2action` can be sent.
-} 
type alias Config model action =
    { prefix : String
    , models : Signal model
    , delta2update : model -> model -> Maybe HashUpdate
    , location2action : List String -> List action
    , address : Address action
    }


{-| The value that you will most often want to supply as the
`prefix` in your [`Config`](#Config). It is equal to "#!/".
-}
defaultPrefix : String
defaultPrefix = "#!/"


{-| Call this function once with your [configuration](#Config).

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

See [`Config`](#Config) for the documentation of the parameter you need to supply.
-}
start : Config model action -> Signal (Task () ())
start config =
    let
        -- A signal of the model changes ... the first element in the tuple is
        -- old value, and the second is the new value.
        -- 
        -- changes : Signal (model, model)
        changes =
            deltas config.models


        -- A mailbox which tracks whether we are in the middle of sending a list
        -- of actions, because of location2action. If we're in the middle, then
        -- we don't want to consider changes ... we only want to consider the
        -- change after all the actions are done.
        --
        -- processingActions : Mailbox Bool
        processingActions =
            mailbox False

        
        -- A signal of changes that were initiated externally, that is, not by
        -- sending actions produced by locattion2action.
        --
        -- When processingActions flips from False -> True, then we output
        -- Nothing.
        --
        -- When processingActions flips from True -> False, we won't output
        -- anything until the *next* change, because we're using sampleOn.
        --
        -- So, essentially this completely disables `delta2update` while the
        -- actions returned by `location2action` are running.
        --
        -- externalChanges : Signal (Maybe (model, model))
        externalChanges =
            Signal.Extra.zip changes processingActions.signal |>
                sampleOn changes |>
                    Signal.map (\zipped ->
                        if snd zipped
                            then Nothing
                            else Just (fst zipped)
                    )


        -- A signal of the hash in the location bar, but normalized to a List
        -- String.
        -- 
        -- locations : Signal (List String)
        locations = 
            Signal.map (hash2list config.prefix) History.hash


        -- Given each change, what update would we make to the location?
        --  
        -- updates : Signal (Maybe HashUpdate)
        possibleUpdates =
            Signal.map computeUpdate externalChanges
    
       
        -- Given a possible change, run delta2update if it's a Just.
        -- Otherwise, return Nothing
        --
        -- computeUpdate : Maybe (model, model) -> Maybe HashUpdate
        computeUpdate maybeChange =
            maybeChange `Maybe.andThen` (uncurry config.delta2update)


        -- A signal of the updates, filtering out those which wouldn't
        -- actually change the current location.
        --    
        -- actualUpdates : Signal HashUpdate
        actualUpdates =
            -- Note that we use passivMap2 so that the signal only updates when
            -- the model changes. That is, we're consulting the location, not
            -- firing when the location changes. This helps avoid a situation
            -- where we create an infinite loop ... that is, where the location
            -- chnage triggers a model change, which triggers a location
            -- change.  The other thing which helps avoid this is that we
            -- check, via dropIfCurrent, whether we're **actually** changing
            -- the location.
            passiveMap2 dropIfCurrent possibleUpdates locations


        -- A Signal of Tasks that actually update the location.
        --    
        -- updateTasks : Signal (Task () ())
        updateTasks =
            Signal.filterMap (Maybe.map update2task) (Task.succeed ()) actualUpdates

        
        -- Converts an a HashUpdate to a Task.
        --
        -- update2task : HashUpdate -> Task () ()
        update2task update =
            list2hash config.prefix (extract update) |>
                case update of
                    SetPath list ->
                        History.setPath

                    ReplacePath list ->
                        History.replacePath


        -- actions : Signal (List action)
        actions =
            passiveMap2 route locations actualUpdates


        -- route : List String -> Maybe HashUpdate -> List action
        route location update =
            case update of
                Just (SetPath list) ->
                    if list == location
                        then [] 
                        else config.location2action location

                Just (ReplacePath list) ->
                    if list == location
                        then []
                        else config.location2action location

                Nothing ->
                    config.location2action location


        -- actionTasks : Signal (Task () ())
        actionTasks =
            Signal.filterMap action2task (Task.succeed ()) actions


        -- action2task : List action -> Maybe (Task () ())
        action2task actions =
            case actions of
                [] ->
                    Nothing

                _ ->
                    Just <|
                        Task.map (always ()) <|
                            Task.sequence <|
                                [ Signal.send processingActions.address True ]
                                ++
                                List.map (Signal.send config.address) actions  
                                ++
                                [ Signal.send processingActions.address False ]

    in
        Signal.merge actionTasks updateTasks


{-|  Tests whether an update would actually change our location. -}
dropIfCurrent : Maybe HashUpdate -> List String -> Maybe HashUpdate
dropIfCurrent update current =
    update `Maybe.andThen` \u ->
        if extract u == current
            then Nothing
            else update


{-| Remove the character from the string if it is the first character -}
removeInitial : Char -> String -> String
removeInitial initial original =
    case uncons original of
        Just (first, rest) ->
            if first == initial
                then rest
                else original
        
        _ ->
            original


{-| Remove initial characters from the string, as many as there are.

So, for "#!/", remove # if is first, then ! if it is next, etc.
-}
removeInitialSequence : String -> String -> String
removeInitialSequence initial original =
    String.foldl removeInitial original initial


{-| Takes a string from the location's hash, and normalize it to a list of strings
that were separated by a slash. -}
hash2list : String -> String -> List String
hash2list prefix =
    removeInitialSequence prefix >> split "/" >> List.map uriDecode


{-| The opposite of normalizeHash ... takes a list and turns it into a hash -}
list2hash : String -> List String -> String
list2hash prefix list =
    prefix ++ String.join "/" (List.map uriEncode list)
