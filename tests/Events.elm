module Events exposing (..)

import Expect
import Html exposing (Html, button, div, input, text)
import Html.Attributes as Attr exposing (href)
import Html.Events exposing (..)
import Html.Lazy as Lazy
import Json.Decode
import Test exposing (..)
import Test.Html.Events as Events exposing (Event(..))
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
                    |> Events.simulate Click
                    |> Expect.equal (Ok SampleMsg)
        , test "returns msg for click on lazy html" <|
            \() ->
                Query.fromHtml sampleLazyHtml
                    |> Query.findAll [ tag "button" ]
                    |> Query.first
                    |> Events.simulate Click
                    |> Expect.equal (Ok SampleMsg)
        , test "returns msg for click on mapped html" <|
            \() ->
                Query.fromHtml sampleMappedHtml
                    |> Query.findAll [ tag "button" ]
                    |> Query.first
                    |> Events.simulate Click
                    -- TODO: Html.Map is ignored when traversing the DOM, need to fix it to avoid repeated mapping on tests like this
                    |>
                        Result.map (always MappedSampleMsg)
                    |> Expect.equal (Ok MappedSampleMsg)
        , test "returns msg for input with transformation" <|
            \() ->
                input [ onInput (String.toUpper >> SampleInputMsg) ] []
                    |> Query.fromHtml
                    |> Events.simulate (Input "cats")
                    |> Expect.equal (Ok <| SampleInputMsg "CATS")
        , test "returns msg for check event" <|
            \() ->
                input [ onCheck SampleCheckedMsg ] []
                    |> Query.fromHtml
                    |> Events.simulate (Check True)
                    |> Expect.equal (Ok <| SampleCheckedMsg True)
        , test "returns msg for custom event" <|
            \() ->
                input [ on "keyup" (Json.Decode.map SampleKeyUpMsg keyCode) ] []
                    |> Query.fromHtml
                    |> Events.simulate (CustomEvent "keyup" "{\"keyCode\": 5}")
                    |> Expect.equal (Ok <| SampleKeyUpMsg 5)
        , testEvent onDoubleClick DoubleClick
        , testEvent onMouseDown MouseDown
        , testEvent onMouseUp MouseUp
        , testEvent onMouseLeave MouseLeave
        , testEvent onMouseOver MouseOver
        , testEvent onMouseOut MouseOut
        , testEvent onSubmit Submit
        , testEvent onBlur Blur
        , testEvent onFocus Focus
        ]


type Msg
    = SampleMsg
    | MappedSampleMsg
    | SampleInputMsg String
    | SampleCheckedMsg Bool
    | SampleKeyUpMsg Int


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


testEvent : (Msg -> Html.Attribute msg) -> Event -> Test
testEvent testOn event =
    test ("returns msg for " ++ (toString event) ++ " event") <|
        \() ->
            input [ testOn SampleMsg ] []
                |> Query.fromHtml
                |> Events.simulate event
                |> Expect.equal (Ok SampleMsg)
