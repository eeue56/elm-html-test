module ExampleApp exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


type alias Model =
    ()


exampleModel : Model
exampleModel =
    ()


view : Model -> Html msg
view model =
    div [ class "container" ]
        [ header [ class "funky themed", id "heading" ]
            [ a [ href "example.com" ] [ text "Home" ]
            , a [ href "example.com/about" ] [ text "About" ]
            ]
        , section [ class "funky themed", id "section" ]
            [ ul [ class "some-list" ]
                [ li [ class "list-item themed" ] [ text "first item" ]
                , li [ class "list-item themed" ] [ text "second item" ]
                , li [ class "list-item themed selected" ] [ text "third item" ]
                , li [ class "list-item themed" ] [ text "fourth item" ]
                ]
            ]
        ]
