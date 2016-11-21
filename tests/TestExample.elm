module TestExample exposing (all)

import Expect
import Test exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector exposing (..)
import ExampleApp exposing (view, exampleModel)


all : Test
all =
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
            , test "expect footer to have footer text" <|
                \() ->
                    output
                        |> Query.find [ tag "footer" ]
                        |> Query.has [ tag "footer", text "this is the footer" ]
            , test "expect each <li> to have classes list-item and themed" <|
                \() ->
                    output
                        |> Query.find [ tag "ul" ]
                        |> Query.findAll [ tag "li" ]
                        |> Query.each (Query.has [ classes [ "list-item", "themed" ] ])
            ]
