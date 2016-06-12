{- This example app shows how to use navigation functionality for showing
   different "pages" (views) based on url. Updates to url render different page views.
-}


module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (style, href, src)
import Html.Events exposing (..)
import Navigation
import String


main : Program Never
main =
  Navigation.program urlParser
    { init = init
    , view = view
    , update = update
    , urlUpdate = urlUpdate
    , subscriptions = subscriptions
    }



-- URL PARSERS - check out evancz/url-parser for fancier URL parsing


fromUrl : String -> Maybe Int
fromUrl url =
  (String.dropLeft 2 url)
    |> String.toInt
    |> Result.toMaybe


urlParser : Navigation.Parser (Maybe Int)
urlParser =
  Navigation.makeParser (fromUrl << .hash)



-- MODEL


{-| In this example we have two different pages, one for user list and one for
  selected user's profile.
-}
type Page
  = UserListPage
  | ProfilePage


type alias User =
  { id : Int
  , name : String
  , profilePicture : String
  }


type alias Model =
  { userList : List User
  , currentPage : Page
  , selectedUserId : Maybe Int
  }


users : List User
users =
  [ { id = 0
    , name = "John"
    , profilePicture = "http://placekitten.com/400/400"
    }
  , { id = 1
    , name = "Lisa"
    , profilePicture = "http://placekitten.com/g/400/400"
    }
  ]


initialModel : Model
initialModel =
  { userList = users
  , currentPage = UserListPage
  , selectedUserId = Nothing
  }


init : Maybe Int -> ( Model, Cmd Msg )
init userId =
  urlUpdate userId initialModel



-- UPDATE


type Msg
  = ListUsers
  | SelectUser Int


{-| The update function either resets the model (no user is selected) or retains current model
  and navigates to selected profile (by user id).
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    ListUsers ->
      ( initialModel, Cmd.none )

    SelectUser id ->
      ( model, Navigation.newUrl ("#/" ++ toString id) )


{-| The url is modeled as maybe to separate profile url from index url. Displayed page is
  updated based on whether the url contains user id or not.
-}
urlUpdate : Maybe Int -> Model -> ( Model, Cmd Msg )
urlUpdate userId model =
  case userId of
    Just id ->
      ( { model
          | currentPage = ProfilePage
          , selectedUserId = userId
        }
      , Cmd.none
      )

    Nothing ->
      ( { model | currentPage = UserListPage }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none



-- VIEW


{-| Some HTML is shared between different pages. If we had a navigation
  bar or a header we would add them here. Instead we just add some white-space
  around the application.
-}
view : Model -> Html Msg
view model =
  div
    [ style
        [ ( "padding", "0 1rem" )
        ]
    ]
    [ pageView model ]


{-| The actual view is modeled after current page. Both pages have an unique structure. If we
  were to add more pages, we would need to also connect the page to a view.
-}
pageView : Model -> Html Msg
pageView model =
  case model.currentPage of
    UserListPage ->
      userListPageView model

    ProfilePage ->
      profilePageView model


userListPageView : Model -> Html Msg
userListPageView model =
  div []
    [ h1 [] [ text "Users" ]
    , ul []
        (List.map userItem model.userList)
    ]


{-| The profile page can contain two kinds of information. In the case of
  a valid profile selection we can display the profile content. A valid
  user id might not be present in the url, or user list may not contain the
  selected user, though. In those cases we need to display an error message.
-}
profilePageView : Model -> Html msg
profilePageView model =
  let
    findUser userId =
      model.userList
        |> List.filter (\user -> user.id == userId)
        |> List.head
  in
    div []
      [ h1 [] [ text "Profile" ]
      , model.selectedUserId
          |> (flip Maybe.andThen) findUser
          |> Maybe.map profileContent
          |> Maybe.withDefault (text "User not found")
      , a [ href "#/" ] [ text "Back to user list" ]
      ]


userItem : User -> Html Msg
userItem user =
  li
    [ style
        [ ( "margin-bottom", "0.5rem" )
        , ( "cursor", "pointer" )
        , ( "text-decoration", "underline" )
        ]
    , onClick (SelectUser user.id)
    ]
    [ text user.name ]


profileContent : User -> Html msg
profileContent user =
  div []
    [ h2 []
        [ text user.name ]
    , img [ src user.profilePicture ]
        []
    ]
