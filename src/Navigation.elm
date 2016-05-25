effect module Navigation where { command = MyCmd, subscription = MySub } exposing
  ( back, forward
  , newUrl, modifyUrl
  , program, programWithFlags
  , Parser, makeParser, Location
  )

{-| This is a library for managing browser navigation yourself.

The core functionality is the ability to &ldquo;navigate&rdquo; to new URLs,
changing the address bar of the broswer *without* the browser kicking off a
request to your servers. Instead, you manage the changes yourself in Elm.


# Change the URL
@docs newUrl, modifyUrl

# Navigation
@docs back, forward

# Start your Program
@docs program, programWithFlags, Parser, makeParser, Location

-}


import Dom.LowLevel exposing (onWindow)
import Html exposing (Html)
import Html.App as App
import Json.Decode as Json
import Native.Navigation
import Process
import Task exposing (Task)



-- PROGRAMS


type MyMsg msg
  = Change Location
  | UserMsg msg


{-| Works the same as the `program` function, but can handle flags. See
[`Html.App.programWithFlags`][doc] for more information.

[doc]: http://package.elm-lang.org/packages/elm-lang/html/latest/Html-App#programWithFlags
-}
programWithFlags
  : Parser data
  ->
    { init : flags -> data -> (model, Cmd msg)
    , update : msg -> model -> (model, Cmd msg)
    , urlUpdate : data -> model -> (model, Cmd msg)
    , view : model -> Html msg
    , subscriptions : model -> Sub msg
    }
  -> Program flags
programWithFlags (Parser parser) stuff =
  let
    update msg model =
      updateHelp UserMsg <|
        case msg of
          Change location ->
            stuff.urlUpdate (parser location) model

          UserMsg userMsg ->
            stuff.update userMsg model

    subs model =
      Sub.batch
        [ subscription (Monitor Change)
        , Sub.map UserMsg (stuff.subscriptions model)
        ]

    view model =
      App.map UserMsg (stuff.view model)

    location =
      Native.Navigation.getLocation ()

    init flags =
      updateHelp UserMsg (stuff.init flags (parser location))
  in
    App.programWithFlags
      { init = init
      , view = view
      , update = update
      , subscriptions = subs
      }


updateHelp : (a -> b) -> (model, Cmd a) -> (model, Cmd b)
updateHelp func (model, cmds) =
  (model, Cmd.map func cmds)


{-| This function augments [`Html.App.program`][doc]. The new things include:

  - `Parser` &mdash; Whenever this library changes the URL, the parser you
  provide will run. This turns the raw URL string into useful data.

  - `urlUpdate` &mdash; Whenever the `Parser` produces new data, we need to
  update our model in some way to react to the change. The `urlUpdate` function
  handles this case. (It works exactly like the normal `update` function. Take
  in a message, update the model.)

[doc]: http://package.elm-lang.org/packages/elm-lang/html/latest/Html-App#program

**Note:** The `urlUpdate` function is called every time the URL changes. This
includes things exposed by this library, like `back` and `newUrl`, as well as
whenever the user clicks the back or forward buttons of the browsers. If the
address changes, you should hear about it.
-}
program
  : Parser data
  ->
    { init : data -> (model, Cmd msg)
    , update : msg -> model -> (model, Cmd msg)
    , urlUpdate : data -> model -> (model, Cmd msg)
    , view : model -> Html msg
    , subscriptions : model -> Sub msg
    }
  -> Program Never
program parser stuff =
  programWithFlags parser { stuff | init = \_ -> stuff.init }



-- TIME TRAVEL


{-| Go back some number of pages. So `back 1` goes back one page, and `back 2`
goes back two pages.

**Note:** You only manage the browser history that *you* created. Think of this
library as letting you have access to a small part of the overall history. So
if you go back farther than the history you own, you will just go back to some
other website!
-}
back : Int -> Cmd msg
back n =
  command (Jump -n)


{-| Go forward some number of pages. So `forward 1` goes forward one page, and
`forward 2` goes forward two pages. If there are no more pages in the future,
this will do nothing.

**Note:** You only manage the browser history that *you* created. Think of this
library as letting you have access to a small part of the overall history. So
if you go forward farther than the history you own, the user will end up on
whatever website they visited next!
-}
forward : Int -> Cmd msg
forward n =
  command (Jump n)



-- CHANGE HISTORY


{-| Step to a new URL. This will add a new entry to the browser history.

**Note:** If the user has gone `back` a few pages, there will be &ldquo;future
pages&rdquo; that the user can go `forward` to. Adding a new URL in that
scenario will clear out any future pages. It is like going back in time and
making a different choice.
-}
newUrl : String -> Cmd msg
newUrl url =
  command (New url)


{-| Modify the current URL. This *will not* add a new entry to the browser
history. It just changes the one you are on right now.
-}
modifyUrl : String -> Cmd msg
modifyUrl url =
  command (Modify url)



-- PARSING


{-| This library is primarily about treating the address bar as an input to
your program. A `Parser` helps you turn the string in the address bar into
data that is easier for your app to handle.
-}
type Parser a =
  Parser (Location -> a)


{-| The `makeParser` function lets you parse the navigation state any way you
want.

**Note:** Check out the examples associated with this GitHub repo to see a
simple usage. See [`evancz/url-parser`][parse] for a more complex example of
URL parsing. The approach used there makes it pretty easy to turn strings into
structured data, and I hope it will serve as a baseline for other URL parsing
libraries that folks make.

[parse]: https://github.com/evancz/url-parser
-}
makeParser : (Location -> a) -> Parser a
makeParser =
  Parser


{-| A bunch of information about the address bar.

**Note:** These fields correspond exactly with the fields of `document.location`
as described [here](https://developer.mozilla.org/en-US/docs/Web/API/Location).
Good luck with that.

**Note 2:** You should be using a library like [`evancz/url-parser`][parse] to
deal with all this stuff, so generally speaking, you should not have to deal
with locations directly.

[parse]: https://github.com/evancz/url-parser
-}
type alias Location =
  { href : String
  , host : String
  , hostname : String
  , protocol : String
  , origin : String
  , port_ : String
  , pathname : String
  , search : String
  , hash : String
  , username : String
  , password : String
  }



-- EFFECT MANAGER


type MyCmd msg
  = Jump Int
  | New String
  | Modify String


cmdMap : (a -> b) -> MyCmd a -> MyCmd b
cmdMap _ myCmd =
  case myCmd of
    Jump n ->
      Jump n

    New url ->
      New url

    Modify url ->
      Modify url


type MySub msg =
  Monitor (Location -> msg)


subMap : (a -> b) -> MySub a -> MySub b
subMap func (Monitor tagger) =
  Monitor (tagger >> func)


(&>) task1 task2 =
  task1 `Task.andThen` \_ -> task2


type alias State msg =
  { subs : List (MySub msg)
  , process : Maybe Process.Id
  }


init : Task Never (State msg)
init =
  Task.succeed (State [] Nothing)


onSelfMsg : Platform.Router msg Location -> Location -> State msg -> Task Never (State msg)
onSelfMsg router location state =
  notify router state.subs location
    &> Task.succeed state


onEffects : Platform.Router msg Location -> List (MyCmd msg) -> List (MySub msg) -> State msg -> Task Never (State msg)
onEffects router cmds subs {process} =
  let
    stepState =
      case (subs, process) of
        ([], Just pid) ->
          Process.kill pid
            &> Task.succeed (State subs Nothing)

        (_ :: _, Nothing) ->
          spawnPopState router
            `Task.andThen` \pid ->

          Task.succeed (State subs (Just pid))

        (_, _) ->
          Task.succeed (State subs process)

  in
    Task.sequence (List.map (cmdHelp router subs) cmds)
      &> stepState


cmdHelp : Platform.Router msg Location -> List (MySub msg) -> MyCmd msg -> Task Never ()
cmdHelp router subs cmd =
  case cmd of
    Jump n ->
      go n

    New url ->
      pushState url `Task.andThen` notify router subs

    Modify url ->
      replaceState url `Task.andThen` notify router subs


notify : Platform.Router msg Location -> List (MySub msg) -> Location -> Task x ()
notify router subs location =
  let
    send (Monitor tagger) =
      Platform.sendToApp router (tagger location)
  in
    Task.sequence (List.map send subs)
      &> Task.succeed ()


spawnPopState : Platform.Router msg Location -> Task x Process.Id
spawnPopState router =
  Process.spawn <| onWindow "popstate" Json.value <| \_ ->
    Platform.sendToSelf router (Native.Navigation.getLocation ())


go : Int -> Task x ()
go =
  Native.Navigation.go


pushState : String -> Task x Location
pushState =
  Native.Navigation.pushState


replaceState : String -> Task x Location
replaceState =
  Native.Navigation.replaceState
