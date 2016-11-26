module Queries exposing (..)

import Html exposing (Html, div, ul, li, header, footer, a, section)
import Html.Attributes as Attr exposing (href)
import Test.Html.Query as Query exposing (Single)
import Test.Html.Selector exposing (..)
import Test exposing (..)
import Expect


all : Test
all =
    Test.concat
        [ testFindAll
        , testFind
        , testRoot
        , testFirst
        , testIndex
        , testChildren
        ]


testRoot : Test
testRoot =
    describe "root query without find or findAll"
        [ describe "finds itself" <|
            [ test "sees it's a <section class='root'>" <|
                \() ->
                    output
                        |> Expect.all
                            [ Query.has [ class "root" ]
                            , Query.has [ tag "section" ]
                            ]
            , test "recognizes its exact className" <|
                \() ->
                    output
                        |> Query.has [ className "root" ]
            , test "recognizes its class by classes" <|
                \() ->
                    output
                        |> Query.has [ classes [ "root" ] ]
            ]
        ]


testFind : Test
testFind =
    describe "Query.find []"
        [ describe "finds the one child" <|
            [ test "sees it's a <div class='container'>" <|
                \() ->
                    output
                        |> Query.find []
                        |> Expect.all
                            [ Query.has [ class "container" ]
                            , Query.has [ tag "div" ]
                            ]
            , test "recognizes its exact className" <|
                \() ->
                    output
                        |> Query.find []
                        |> Query.has [ className "container" ]
            , test "recognizes its class by classes" <|
                \() ->
                    output
                        |> Query.find []
                        |> Query.has [ classes [ "container" ] ]
            ]
        ]


testFindAll : Test
testFindAll =
    describe "Query.findAll []"
        [ describe "finds the one child" <|
            [ test "and only the one child" <|
                \() ->
                    output
                        |> Query.findAll []
                        |> Query.count (Expect.equal 1)
            , test "sees it's a <div class='container'>" <|
                \() ->
                    output
                        |> Query.findAll []
                        |> Expect.all
                            [ Query.each (Query.has [ class "container" ])
                            , Query.each (Query.has [ tag "div" ])
                            ]
            , test "recognizes its exact className" <|
                \() ->
                    output
                        |> Query.findAll []
                        |> Query.each (Query.has [ className "container" ])
            , test "recognizes its class by classes" <|
                \() ->
                    output
                        |> Query.findAll []
                        |> Query.each (Query.has [ classes [ "container" ] ])
            ]
        , describe "finds multiple descendants"
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


testFirst : Test
testFirst =
    describe "Query.first"
        [ describe "finds the one child" <|
            [ test "sees it's a <div class='container'>" <|
                \() ->
                    output
                        |> Query.findAll []
                        |> Query.first
                        |> Query.has [ tag "div", class "container" ]
            ]
        ]


testIndex : Test
testIndex =
    describe "Query.index"
        [ describe "Query.index 0" <|
            [ test "sees it's a <div class='container'>" <|
                \() ->
                    output
                        |> Query.findAll []
                        |> Query.index 0
                        |> Query.has [ tag "div", class "container" ]
            ]
        , describe "Query.index -1" <|
            [ test "sees it's a <div class='container'>" <|
                \() ->
                    output
                        |> Query.findAll []
                        |> Query.index -1
                        |> Query.has [ tag "div", class "container" ]
            ]
        ]


testChildren : Test
testChildren =
    describe "Query.children"
        [ describe "on the root" <|
            [ test "sees the root has one child" <|
                \() ->
                    output
                        |> Query.children
                        |> Query.count (Expect.equal 1)
            , test "sees it's a <header id='heading'>" <|
                \() ->
                    output
                        |> Query.children
                        |> Query.each (Query.has [ tag "header", id "heading" ])
            ]
        ]


output : Single
output =
    Query.fromHtml sampleHtml


sampleHtml : Html msg
sampleHtml =
    section [ Attr.class "root" ]
        [ div [ Attr.class "container" ]
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
        ]
