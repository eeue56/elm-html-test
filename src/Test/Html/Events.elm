module Test.Html.Events
    exposing
        ( Event(..)
        , simulate
        , expectEvent
        )

{-|

This module allows you to simulate events on Html nodes, the Msg generated
by the event is returned so you can test it

@docs Event, simulate, expectEvent

-}

import Dict
import ElmHtml.InternalTypes exposing (ElmHtml, ElmHtml(..), Tagger)
import Json.Decode exposing (decodeString)
import Json.Encode exposing (bool, encode, object, string)
import Native.HtmlAsJson
import Test.Html.Query as Query
import Test.Html.Query.Internal as QueryInternal
import Expect exposing (Expectation)


type EventNode
    = EventNode Event QueryInternal.Single


{-| Event constructors to simulate events
-}
type Event
    = Click
    | DoubleClick
    | MouseDown
    | MouseUp
    | MouseEnter
    | MouseLeave
    | MouseOver
    | MouseOut
    | Input String
    | Check Bool
    | Submit
    | Blur
    | Focus
    | CustomEvent String String


{-| Gets a Msg produced by a node when an event is simulated.

    type Msg
        = Change String

    test "Input produces expected Msg" <|
        \() ->
            Html.input [ onInput Change ] [ ]
                |> Query.fromHtml
                |> Events.simulate (Input "cats")
                |> Events.expectEvent (Change "cats")

-}
simulate : Event -> Query.Single -> EventNode
simulate event single =
    EventNode event single


{-| Passes if given event equals the triggered event

    type Msg
        = Change String

    test "Input produces expected Msg" <|
        \() ->
            Html.input [ onInput Change ] [ ]
                |> Query.fromHtml
                |> Events.simulate (Input "cats")
                |> Events.expectEvent (Change "cats")

-}
expectEvent : msg -> EventNode -> Expectation
expectEvent msg (EventNode event (QueryInternal.Single showTrace query)) =
    let
        ( eventName, jsEvent ) =
            rawEvent event

        node =
            QueryInternal.traverse query
                |> Result.andThen (QueryInternal.verifySingle eventName)
                |> Result.mapError (QueryInternal.queryErrorToString query)
    in
        case node of
            Err msg ->
                Expect.fail msg
                    |> QueryInternal.failWithQuery showTrace ("Query.find") query

            Ok single ->
                case findEvent eventName single of
                    Err noEvent ->
                        Expect.fail noEvent
                            |> QueryInternal.failWithQuery showTrace "" query

                    Ok foundEvent ->
                        decodeString foundEvent jsEvent
                            |> Result.map (\foundMsg -> Expect.equal msg foundMsg)
                            |> Result.withDefault (Expect.fail "Failed to decode string")
                            |> QueryInternal.failWithQuery showTrace ("Event.expectEvent: Expected the msg \x1B[32m" ++ toString msg ++ "\x1B[39m from the event \x1B[31m" ++ toString event ++ "\x1B[39m but could not find the event.") query


rawEvent : Event -> ( String, String )
rawEvent event =
    case event of
        Click ->
            ( "click", "{}" )

        DoubleClick ->
            ( "dblclick", "{}" )

        MouseDown ->
            ( "mousedown", "{}" )

        MouseUp ->
            ( "mouseup", "{}" )

        MouseEnter ->
            ( "mouseenter", "{}" )

        MouseLeave ->
            ( "mouseleave", "{}" )

        MouseOver ->
            ( "mouseover", "{}" )

        MouseOut ->
            ( "mouseout", "{}" )

        Input value ->
            ( "input"
            , object
                [ ( "target"
                  , object [ ( "value", string value ) ]
                  )
                ]
                |> encode 0
            )

        Check checked ->
            ( "change"
            , object
                [ ( "target"
                  , object [ ( "checked", bool checked ) ]
                  )
                ]
                |> encode 0
            )

        Submit ->
            ( "submit", "{}" )

        Blur ->
            ( "blur", "{}" )

        Focus ->
            ( "focus", "{}" )

        CustomEvent name event ->
            ( name, event )


findEvent : String -> ElmHtml -> Result String (Json.Decode.Decoder msg)
findEvent eventName element =
    let
        elementOutput =
            QueryInternal.prettyPrint element

        taggedEventDecoder node =
            node.facts.events
                |> Dict.get eventName
                |> Maybe.map eventDecoder
                |> Maybe.map (tagEventDecoder node)
                |> Result.fromMaybe ("Events.expectEvent: The event \x1B[32m" ++ eventName ++ "\x1B[39m does not exist on the found node.\n\n" ++ elementOutput)
    in
        case element of
            TextTag _ ->
                Err ("Found element is a text, which does not produce events, therefore could not simulate " ++ eventName ++ " on it. Text found: " ++ elementOutput)

            NodeEntry node ->
                taggedEventDecoder node

            CustomNode node ->
                taggedEventDecoder node

            MarkdownNode node ->
                taggedEventDecoder node

            NoOp ->
                Err ("Unknown element found. Could not simulate " ++ eventName ++ " on it.")


tagEventDecoder : { c | facts : { b | taggers : List Tagger } } -> Json.Decode.Decoder a -> Json.Decode.Decoder a
tagEventDecoder node eventDecoder =
    let
        htmlMap =
            node.facts.taggers
                |> List.map taggerFunction
                |> List.foldl (<<) identity
    in
        Json.Decode.map htmlMap eventDecoder


eventDecoder : Json.Decode.Value -> Json.Decode.Decoder msg
eventDecoder event =
    Native.HtmlAsJson.eventDecoder event


taggerFunction : Tagger -> (a -> msg)
taggerFunction tagger =
    Native.HtmlAsJson.taggerFunction tagger
