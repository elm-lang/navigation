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
    , subscriptions = subscriptions
    }



-- URL PARSERS - check out evancz/url-parser for fancier URL parsing


toUrl : Int -> String
toUrl count =
  "#/" ++ toString count


fromUrl : String -> Int
fromUrl url =
  case String.toInt (String.dropLeft 2 url) of
    Err _ -> 0
    Ok count -> count


urlParser : Navigation.Location -> Msg
urlParser location =
  HashChange (fromUrl location.hash)



-- MODEL


type alias Model = Int


init : Navigation.Location -> (Model, Cmd Msg)
init location =
  ( (fromUrl location.hash), Cmd.none )



-- UPDATE


type Msg = Increment | Decrement | HashChange Int


{-| A relatively normal update function. The only notable thing here is that we
are commanding a new URL to be added to the browser history. This changes the
address bar and lets us use the browser&rsquo;s back button to go back to
previous pages.
-}
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Increment ->
      (model, Navigation.newUrl (toUrl (model + 1)))

    Decrement ->
      (model, Navigation.newUrl (toUrl (model - 1)))

    HashChange count ->
      (count, Cmd.none)



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
