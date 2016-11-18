port module Main exposing (..)

import Test.Runner.Node exposing (run, TestProgram)
import Expect
import Test exposing (..)
import Json.Encode exposing (Value)
import Html exposing (..)
import Html.Attributes as Attr
import Test.Html.Query as Query
import Test.Html.Query.Criteria exposing (..)


main : TestProgram
main =
    [ testText
    ]
        |> Test.concat
        |> run emit


port emit : ( String, Value ) -> Cmd msg


type alias Model =
    ()


model : Model
model =
    ()


view : Model -> Html msg
view model =
    div [ Attr.class "container" ]
        [ header [ Attr.class "funky themed", Attr.id "heading" ]
            [ a [ Attr.href "example.com" ] [ text "Home" ]
            , a [ Attr.href "example.com/about" ] [ text "About" ]
            ]
        , section [ Attr.class "funky themed", Attr.id "section" ]
            [ ul [ Attr.class "some-list" ]
                [ li [ Attr.class "list-item themed" ] [ text "first item" ]
                , li [ Attr.class "list-item themed" ] [ text "second item" ]
                , li [ Attr.class "list-item themed selected" ] [ text "third item" ]
                , li [ Attr.class "list-item themed" ] [ text "fourth item" ]
                ]
            ]
        ]


testText : Test
testText =
    describe "working with HTML text"
        [ test "(this should fail) header has four links in it" <|
            \() ->
                model
                    |> view
                    |> Query.find [ id "heading" ]
                    |> Query.children [ tag "a" ]
                    |> Query.count (Expect.equal 4)
        ]
