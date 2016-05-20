effect module Navigation where { command = MyCmd, subscription = MySub } exposing
  ( back, forward, jump
  , add, replace
  , program, programWithFlags
  , Parser, makeParser, State, Location
  )

{-|
-}


import Html exposing (Html)
import Html.App as App
import Native.Navigation
import Task



-- PROGRAMS


type MyMsg msg
  = Change State
  | UserMsg msg


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
          Change state ->
            stuff.urlUpdate (parser state) model

          UserMsg userMsg ->
            stuff.update userMsg model

    subs model =
      Sub.batch
        [ subscription (Monitor Change)
        , Sub.map UserMsg (stuff.subscriptions model)
        ]

    view model =
      App.map UserMsg (stuff.view model)

    {length, location} =
      Native.Navigation.getState ()

    init flags =
      updateHelp UserMsg (stuff.init flags (parser (State location length length)))
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


back : Cmd msg
back =
  jump -1


forward : Cmd msg
forward =
  jump 1


jump : Int -> Cmd msg
jump n =
  command (Jump n)



-- CHANGE HISTORY


add : String -> Cmd msg
add url =
  command (Add url)


replace : String -> Cmd msg
replace url =
  command (Replace url)



-- PARSING


type Parser a =
  Parser (State -> a)


makeParser : (State -> a) -> Parser a
makeParser =
  Parser


type alias State =
  { location : Location
  , length : Int
  , index : Int
  }


{-|
**Note:** These fields correspond exactly with the fields of `document.location`
as described [here](https://developer.mozilla.org/en-US/docs/Web/API/Location).
Good luck.
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
  | Add String
  | Replace String


cmdMap : (a -> b) -> MyCmd a -> MyCmd b
cmdMap _ myCmd =
  case myCmd of
    Jump n ->
      Jump n

    Add url ->
      Add url

    Replace url ->
      Replace url


type MySub msg =
  Monitor (State -> msg)


subMap : (a -> b) -> MySub a -> MySub b
subMap func (Monitor tagger) =
  Monitor (tagger >> func)


init : Task.Task Never Int
init =
  Task.succeed 0


onSelfMsg : Platform.Router msg Never -> Never -> Int -> Task.Task Never Int
onSelfMsg _ _ index =
  Task.succeed index


onEffects : Platform.Router msg Never -> List (MyCmd msg) -> List (MySub msg) -> Int -> Task.Task Never Int
onEffects router cmds subs index =
  case cmds of
    [] ->
      Task.succeed index

    cmd :: rest ->
      onEffectsHelp router cmd subs index
        `Task.andThen`

      onEffects router rest subs


onEffectsHelp : Platform.Router msg Never -> MyCmd msg -> List (MySub msg) -> Int -> Task.Task Never Int
onEffectsHelp router cmd subs index =
  case cmd of
    Jump n ->
      go n
        `Task.andThen` \{length, location} ->

      dispatch router subs (State location length (clamp 0 (length - 1) (index + n)))


    Add url ->
      pushState url
        `Task.andThen` \{length, location} ->

      dispatch router subs (State location length (index + 1))

    Replace url ->
      replaceState url
        `Task.andThen` \{length, location} ->

      dispatch router subs (State location length index)


dispatch : Platform.Router msg Never -> List (MySub msg) -> State -> Task.Task Never Int
dispatch router subs state =
  let
    send (Monitor tagger) =
      Platform.sendToApp router (tagger state)
  in
    Task.sequence (List.map send subs)
      `Task.andThen` \_ ->

    Task.succeed state.index


type alias PartialState =
  { length : Int
  , location : Location
  }


go : Int -> Task.Task x PartialState
go =
  Native.Navigation.go


pushState : String -> Task.Task x PartialState
pushState =
  Native.Navigation.pushState


replaceState : String -> Task.Task x PartialState
replaceState =
  Native.Navigation.replaceState
