module Queries exposing (..)

import Html exposing (Html, div, ul, li, header, footer, a, section)
import Html.Attributes as Attr exposing (href)
import Test.Html.Query as Query
import Test.Html.Selector exposing (..)
import Test exposing (..)
import Expect


all =
    Test.concat
        [ testFindAll
        ]


testFindAll =
    let
        output =
            Query.fromHtml sampleHtml
    in
        describe "Query.findAll"
            [ describe "finds itself" <|
                [ test "and only itself" <|
                    \() ->
                        output
                            |> Query.findAll []
                            |> Query.count (Expect.equal 1)
                , test "recognizes its class" <|
                    \() ->
                        output
                            |> Query.findAll []
                            |> Query.each (Query.has [ class "container" ])
                ]
            , describe "finds children"
                [ test "with tag selectors that return one match at the start" <|
                    \() ->
                        output
                            |> Query.findAll [ tag "header" ]
                            |> Query.count (Expect.equal 1)
                , test "with tag selectors that return multiple matches" <|
                    \() ->
                        output
                            |> Query.findAll [ tag "section" ]
                            |> Query.count (Expect.equal 2)
                , test "with tag selectors that return one match at the end" <|
                    \() ->
                        output
                            |> Query.findAll [ tag "footer" ]
                            |> Query.count (Expect.equal 1)
                ]
            ]


sampleHtml : Html msg
sampleHtml =
    div [ Attr.class "container" ]
        [ header [ Attr.class "funky themed", Attr.id "heading" ]
            [ a [ href "http://elm-lang.org" ] [ Html.text "home" ]
            , a [ href "http://elm-lang.org/examples" ] [ Html.text "examples" ]
            , a [ href "http://elm-lang.org/docs" ] [ Html.text "docs" ]
            ]
        , section [ Attr.class "funky themed", Attr.id "section" ]
            [ ul [ Attr.class "some-list" ]
                [ li [ Attr.class "list-item themed" ] [ Html.text "first item" ]
                , li [ Attr.class "list-item themed" ] [ Html.text "second item" ]
                , li [ Attr.class "list-item themed selected" ] [ Html.text "third item" ]
                , li [ Attr.class "list-item themed" ] [ Html.text "fourth item" ]
                ]
            ]
        , section [] [ Html.text "boring section" ]
        , footer [] [ Html.text "this is the footer" ]
        ]
