{- This app is the basic counter app. You can increment and decrement the count
like normal. The big difference is that the current count shows up in the URL.

Try changing the URL by hand. If you change it to a number, the app will go
there. If you change it to some invalid address, the app will recover in a
reasonable way.
-}

import Html exposing (..)
import Html.Events exposing (..)
import Navigation
import String



main =
  Navigation.program urlParser
    { init = init
    , view = view
    , update = update
    , urlUpdate = urlUpdate
    , subscriptions = subscriptions
    }



-- URL PARSERS - check out evancz/url-parser for fancier URL parsing


toUrl : Int -> String
toUrl count =
  "#/" ++ toString count


fromUrl : String -> Result String Int
fromUrl url =
  String.toInt (String.dropLeft 2 url)


urlParser : Navigation.Parser (Result String Int)
urlParser =
  Navigation.makeParser (fromUrl << .hash)



-- MODEL


type alias Model = Int


init : Result String Int -> (Model, Cmd Msg)
init result =
  urlUpdate result 0



-- UPDATE


type Msg = Increment | Decrement


{-| A relatively normal update function. The only notable thing here is that we
are commanding a new URL to be added to the browser history. This changes the
address bar and lets us use the browser&rsquo;s back button to go back to
previous pages.
-}
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  let
    newModel =
      case msg of
        Increment ->
          model + 1

        Decrement ->
          model - 1
  in
    (newModel, Navigation.newUrl (toUrl newModel))


{-| The URL is turned into a result. If the URL is valid, we just update our
model to the new count. If it is not a valid URL, we modify the URL to make
sense.
-}
urlUpdate : Result String Int -> Model -> (Model, Cmd Msg)
urlUpdate result model =
  case result of
    Ok newCount ->
      (newCount, Cmd.none)

    Err _ ->
      (model, Navigation.modifyUrl (toUrl model))



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none



-- VIEW


view : Model -> Html Msg
view model =
  div []
    [ button [ onClick Decrement ] [ text "-" ]
    , div [] [ text (toString model) ]
    , button [ onClick Increment ] [ text "+" ]
    ]
