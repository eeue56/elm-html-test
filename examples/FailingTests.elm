port module Main exposing (..)

import Test.Runner.Node exposing (run, TestProgram)
import Expect
import Test exposing (..)
import Json.Encode exposing (Value)
import Html exposing (..)
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


view : Model -> Html ()
view model =
    text "blahh"


testText : Test
testText =
    describe "working with HTML text"
        [ test "this should fail" <|
            \() ->
                model
                    |> view
                    |> Query.find [ class "foo" ]
                    |> Query.children
                    |> Query.count (Expect.equal 4)
        ]
