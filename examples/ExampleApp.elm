module ExampleApp exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)


type alias Model =
    ()


exampleModel : Model
exampleModel =
    ()


type Msg
    = GoToHome
    | GoToExamples


view : Model -> Html Msg
view model =
    div [ class "container" ]
        [ header [ class "funky themed", id "heading" ]
            [ a [ href "http://elm-lang.org", onClick GoToHome ] [ text "home" ]
            , a [ href "http://elm-lang.org/examples", onClick GoToExamples ] [ text "examples" ]
            , a [ href "http://elm-lang.org/docs" ] [ text "docs" ]
            ]
        , section [ class "funky themed", id "section" ]
            [ ul [ class "some-list" ]
                [ li [ class "list-item themed" ] [ text "first item" ]
                , li [ class "list-item themed" ] [ text "second item" ]
                , li [ class "list-item themed selected" ] [ text "third item" ]
                , li [ class "list-item themed" ] [ text "fourth item" ]
                ]
            ]
        , footer [] [ text "this is the footer" ]
        ]
