module Main exposing (..) -- where


import Html
import Html.App as Html
import Html.Events exposing (onClick)
import Navigation
import String



type Msg
    = Increase
    | Decrease
    | UrlChange
    | Forward
    | Back

type alias Model =
    { count : Int
    , length : Int
    , index : Int
    }


init : Navigation.State -> (Model, Cmd Msg)
init state =
    case parseUrl state of
        Err m ->
            { count = 0
            , length = state.length
            , index = state.index
            }
            ! []

        Ok n ->
            { length = state.length
            , count = n
            , index = state.index
            }
            ! []

parseUrl : Navigation.State -> Result String Int
parseUrl state =
    String.dropLeft 2 state.location.hash
        |> String.toInt


buildUrl : Model -> String
buildUrl model =
    "#/" ++ (toString model.count)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Increase ->
            { model
            | count = model.count + 1
            }
            ! [ Navigation.newUrl (buildUrl model) ]

        Decrease ->
            { model
            | count = model.count - 1
            }
            ! [ Navigation.newUrl (buildUrl model) ]
        UrlChange ->
            model ! []

        Forward ->
            model ! [ Navigation.forward 1 ]

        Back ->
            model ! [ Navigation.back 1 ]

urlUpdate : Navigation.State -> Model -> (Model, Cmd Msg)
urlUpdate state model =
    { model
    | length = state.length
    , index = state.index
    }
    ! []


view : Model -> Html.Html Msg
view model =
    Html.div
        []
        [ Html.div
            [ onClick Increase
            ]
            [ Html.text "Increase"
            ]
        , Html.div
            [ onClick Decrease
            ]
            [ Html.text "Decrease"
            ]
        , Html.div
            [
            ]
            [ Html.text ("Current history length:" ++ (toString model.length))
            ]
        , Html.div
            [
            ]
            [ Html.text ("Current history index:" ++ (toString model.index))
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



main =
    Navigation.program
        (Navigation.makeParser identity)
        { init = init
        , update = update
        , urlUpdate = urlUpdate
        , view = view
        , subscriptions = \_ -> Sub.none
        }
