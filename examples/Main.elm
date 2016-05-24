module Main exposing (..) -- where

{-|
In this module, we're going to show off how to use the Navigation module

Our app will have:
    - Buttons to increase or decrease a count. Each count change also changes the url
    - Buttons to go back and forward through the history of the application
    - When a user goes to a url on their initial access to a page, the count is loaded from the url
-}

import Html
import Html.Events exposing (onClick)
import Navigation
import String


{-|
Let's just define our messages! What do we care about?

- Increasing and decreasing count
- Urls changing
- Going forward and back in history
-}
type Msg
    = IncreaseCount
    | DecreaseCount
    | Forward
    | Back

{-|
Our model is pretty simple - let's store count, but also the index and
length of the history
-}
type alias Model =
    { count : Int
    , historyLength : Int
    , historyIndex : Int
    }

{-|
Our init command takes an initial history state.
We can then try and parse the url to get the count out
-}
init : Navigation.State -> (Model, Cmd Msg)
init state =
    case parseUrl state of
        Err m ->
            { count = 0
            , historyLength = state.length
            , historyIndex = state.index
            }
            ! []

        Ok n ->
            { historyLength = state.length
            , count = n
            , historyIndex = state.index
            }
            ! []

{-|
our urls should look like `#/count`, where `count`
is a number
-}
buildUrl : Model -> String
buildUrl model =
    "#/" ++ (toString model.count)

{-|
we only care about the number after `#/`, so, drop two characters
then try to parse the rest to an int
-}
parseUrl : Navigation.State -> Result String Int
parseUrl state =
    String.dropLeft 2 state.location.hash
        |> String.toInt

{-| Standard update function
-}
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        IncreaseCount ->
            ( { model | count = model.count + 1 }
            , Navigation.newUrl (buildUrl model)
            )

        DecreaseCount ->
            ( { model | count = model.count - 1 }
            ,  Navigation.newUrl (buildUrl model)
            )

        Forward ->
            ( model, Navigation.forward 1)

        Back ->
            ( model, Navigation.back 1)

{-|
`urlUpdate` is called when the url is updated. Makes sense, right?
-}
urlUpdate : Navigation.State -> Model -> (Model, Cmd Msg)
urlUpdate state model =
    ( { model
      | historyLength = state.length
      , historyIndex = state.index
      }
    , Cmd.none
    )

{-| Standard view
-}
view : Model -> Html.Html Msg
view model =
    Html.div
        []
        [ Html.div
            [ onClick IncreaseCount
            ]
            [ Html.text "Increase count"
            ]
        , Html.div
            [ onClick DecreaseCount
            ]
            [ Html.text "Decrease count"
            ]
        , Html.div
            [
            ]
            [ Html.text ("Current history length:" ++ (toString model.historyLength))
            ]
        , Html.div
            [
            ]
            [ Html.text ("Current history index:" ++ (toString model.historyIndex))
            ]
        , Html.div
            [
            ]
            [ Html.text ("Current count :" ++ (toString model.count))
            ]
        , Html.div
            [ onClick Forward
            ]
            [ Html.text "Forward"
            ]
        , Html.div
            [ onClick Back
            ]
            [ Html.text "Back"
            ]
        ]


{-|
Bring it all together using `Navigation.program`, which is a wrapper
around `Html.App.program`
-}
main : Program Never
main =
    Navigation.program
        (Navigation.makeParser identity)
        { init = init
        , update = update
        , urlUpdate = urlUpdate
        , view = view
        , subscriptions = \_ -> Sub.none
        }
