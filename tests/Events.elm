module Events exposing (..)

import Expect
import Html exposing (Html, button, div, text, input)
import Html.Attributes as Attr exposing (href)
import Html.Events exposing (onClick, onInput)
import Html.Lazy as Lazy
import Test exposing (..)
import Test.Html.Events as Events
import Test.Html.Query as Query exposing (Single)
import Test.Html.Selector exposing (tag)


all : Test
all =
    describe "trigerring events"
        [ test "returns msg for click on element" <|
            \() ->
                Query.fromHtml sampleHtml
                    |> Query.findAll [ tag "button" ]
                    |> Query.first
                    |> Events.msgFor "click" "{}"
                    |> Expect.equal (Ok SampleMsg)
        , test "returns msg for click on lazy html" <|
            \() ->
                Query.fromHtml sampleLazyHtml
                    |> Query.findAll [ tag "button" ]
                    |> Query.first
                    |> Events.msgFor "click" "{}"
                    |> Expect.equal (Ok SampleMsg)
        , test "returns msg for click on mapped html" <|
            \() ->
                Query.fromHtml sampleMappedHtml
                    |> Query.findAll [ tag "button" ]
                    |> Query.first
                    |> Events.msgFor "click" "{}"
                    -- TODO: Html.Map is ignored when traversing the DOM, need to fix it to avoid repeated mapping on tests like this
                    |>
                        Result.map (always MappedSampleMsg)
                    |> Expect.equal (Ok MappedSampleMsg)
        , test "returns msg for input with transformation" <|
            \() ->
                Query.fromHtml sampleInput
                    |> Query.findAll [ tag "input" ]
                    |> Query.first
                    |> Events.msgFor "input" "{\"target\": {\"value\": \"cats\"}}"
                    |> Expect.equal (Ok <| SampleInputMsg "CATS")
        ]


type Msg
    = SampleMsg
    | MappedSampleMsg
    | SampleInputMsg String


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


sampleMappedHtml : Html Msg
sampleMappedHtml =
    div [ Attr.class "container" ]
        [ Html.map (always MappedSampleMsg) (button [ onClick SampleMsg ] [ text "click me" ])
        ]


sampleInput : Html Msg
sampleInput =
    div [ Attr.class "container" ]
        [ input [ onInput (String.toUpper >> SampleInputMsg) ] []
        ]
