module Events exposing (..)

import Html exposing (Html, div, button, text)
import Html.Lazy as Lazy
import Html.Attributes as Attr exposing (href)
import Html.Events exposing (onClick)
import Test.Html.Query as Query exposing (Single)
import Test.Html.Events as Events
import Test.Html.Selector exposing (tag)
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
                [ testEvents
                ]


testEvents : Single -> Test
testEvents output =
    describe "trigerring events"
        [ test "triggers click on element" <|
            \() ->
                output
                    |> Query.findAll [ tag "button" ]
                    |> Query.first
                    |> Events.trigger "click" "{}"
                    |> Expect.equal (Ok SampleMsg)
        ]


htmlOutput : Single
htmlOutput =
    Query.fromHtml sampleHtml


lazyOutput : Single
lazyOutput =
    Query.fromHtml sampleLazyHtml


type Msg
    = SampleMsg


sampleHtml : Html Msg
sampleHtml =
    div [ Attr.class "container" ]
        [ button [ onClick SampleMsg ] [ text "click me" ]
        ]


sampleLazyHtml : Html Msg
sampleLazyHtml =
    div [ Attr.class "container" ]
        [ Lazy.lazy
            (\str -> button [ onClick SampleMsg ] [ text str ])
            "click me"
        ]
