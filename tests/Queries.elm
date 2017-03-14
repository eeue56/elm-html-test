module Queries exposing (..)

import Html exposing (Html, div, ul, li, header, footer, a, section)
import Html.Lazy as Lazy
import Html.Attributes as Attr exposing (href)
import Test.Html.Query as Query exposing (Single)
import Test.Html.Selector exposing (..)
import Test exposing (..)
import Expect


all : Test
all =
    let
        html =
            [ htmlOutput, lazyOutput ]
    in
        Test.concat <|
            List.concatMap (\f -> List.map f html)
                [ testFindAll
                , testFind
                , testRoot
                , testFirst
                , testIndex
                , testChildren
                ]


testRoot : Single -> Test
testRoot output =
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


testFind : Single -> Test
testFind output =
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


testFindAll : Single -> Test
testFindAll output =
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
                        |> Query.find [ tag "footer" ]
                        |> Query.has [ text "this is the footer" ]
            , test "sees the nested div" <|
                \() ->
                    output
                        |> Query.findAll [ tag "div" ]
                        |> Query.count (Expect.equal 2)
            ]
        ]


testFirst : Single -> Test
testFirst output =
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


testIndex : Single -> Test
testIndex output =
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


testChildren : Single -> Test
testChildren output =
    describe "Query.children"
        [ describe "on the root" <|
            [ test "returns the child" <|
                \() ->
                    output
                        |> Query.children []
                        |> Query.count (Expect.equal 1)
            , test "sees the child is a <div class='container'>" <|
                \() ->
                    output
                        |> Query.children []
                        |> Query.each (Query.has [ tag "div", class "container" ])
            , test "doesn't see the nested header" <|
                \() ->
                    output
                        |> Query.children [ tag "header" ]
                        |> Query.count (Expect.equal 0)
            ]
        ]


htmlOutput : Single
htmlOutput =
    Query.fromHtml sampleHtml


lazyOutput : Single
lazyOutput =
    Query.fromHtml sampleLazyHtml


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
            , section []
                [ div [ Attr.class "nested-div" ] [ Html.text "boring section" ] ]
            , footer [] [ Html.text "this is the footer" ]
            ]
        ]


sampleLazyHtml : Html msg
sampleLazyHtml =
    section [ Attr.class "root" ]
        [ div [ Attr.class "container" ]
            [ header [ Attr.class "funky themed", Attr.id "heading" ]
                [ Lazy.lazy (\str -> a [ href "http://elm-lang.org" ] [ Html.text str ]) "home"
                , Lazy.lazy (\str -> a [ href "http://elm-lang.org/examples" ] [ Html.text str ]) "examples"
                , Lazy.lazy (\str -> a [ href "http://elm-lang.org/docs" ] [ Html.text str ]) "docs"
                ]
            , section [ Attr.class "funky themed", Attr.id "section" ]
                [ ul [ Attr.class "some-list" ]
                    [ Lazy.lazy (\str -> li [ Attr.class "list-item themed" ] [ Html.text str ]) "first item"
                    , Lazy.lazy (\str -> li [ Attr.class "list-item themed" ] [ Html.text str ]) "second item"
                    , Lazy.lazy (\str -> li [ Attr.class "list-item themed selected" ] [ Html.text str ]) "third item"
                    , Lazy.lazy (\str -> li [ Attr.class "list-item themed" ] [ Html.text str ]) "fourth item"
                    ]
                ]
            , section []
                [ div [ Attr.class "nested-div" ] [ Html.text "boring section" ] ]
            , footer [] [ Lazy.lazy2 (\a b -> Html.text <| a ++ b) "this is " "the footer" ]
            ]
        ]
