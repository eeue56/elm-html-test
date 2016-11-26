port module Main exposing (..)

import Test.Runner.Node exposing (run, TestProgram)
import Expect
import Test exposing (..)
import Json.Encode exposing (Value)
import Test.Html.Query as Query
import Test.Html.Selector exposing (..)
import ExampleApp exposing (view, exampleModel)


main : TestProgram
main =
    [ testView
    ]
        |> Test.concat
        |> run emit


port emit : ( String, Value ) -> Cmd msg


testView : Test
testView =
    let
        output =
            view exampleModel
                |> Query.fromHtml
    in
        describe "view exampleModel"
            [ test "expect 4x <li> somewhere on the page" <|
                \() ->
                    output
                        |> Query.findAll [ tag "li" ]
                        |> Query.count (Expect.equal 4)
            , test "expect 4x <li> inside a <ul>" <|
                \() ->
                    output
                        |> Query.find [ tag "ul" ]
                        |> Query.findAll [ tag "li" ]
                        |> Query.count (Expect.equal 4)
            , test "(this should fail) expect header to have 4 links in it, even though it has 3" <|
                \() ->
                    output
                        |> Query.find [ id "heading" ]
                        |> Query.findAll [ tag "a" ]
                        |> Query.count (Expect.equal 4)
            , test "(this should fail) expect header to have one link in it, even though it has 3" <|
                \() ->
                    output
                        |> Query.find [ id "heading" ]
                        |> Query.find [ tag "a" ]
                        |> Query.has [ tag "a" ]
            , test "(this should fail) expect header to have one <img> in it, even though it has none" <|
                \() ->
                    output
                        |> Query.find [ id "heading" ]
                        |> Query.find [ tag "img" ]
                        |> Query.has [ tag "img" ]
            , test "(this should fail) expect footer to have a child" <|
                \() ->
                    output
                        |> Query.find [ tag "footer" ]
                        |> Query.children
                        |> Query.each (Query.has [ tag "catapult" ])
            , test "(this should fail) expect footer's nonexistant child to be a catapult" <|
                \() ->
                    output
                        |> Query.find [ tag "footer" ]
                        |> Query.children
                        |> Query.first
                        |> Query.has [ tag "catapult" ]
            , test "expect footer to have footer text" <|
                \() ->
                    output
                        |> Query.find [ tag "footer" ]
                        |> Query.has [ tag "footer", text "this is the footer" ]
            , test "(this should fail) expect footer to have text it doesn't have" <|
                \() ->
                    output
                        |> Query.find [ tag "footer" ]
                        |> Query.has [ tag "footer", text "this is SPARTA!!!" ]
            , test "expect each <li> to have classes list-item and themed" <|
                \() ->
                    output
                        |> Query.find [ tag "ul" ]
                        |> Query.findAll [ tag "li" ]
                        |> Query.each (Query.has [ classes [ "list-item", "themed" ] ])
            ]
