module Test.Html.Events
    exposing
        ( Event(..)
        , EventNode
        , simulate
        , expectEvent
        , eventResult
        )

{-|

This module allows you to simulate events on Html nodes, the Msg generated
by the event is returned so you can test it

@docs Event, simulate, expectEvent, eventResult

-}

import Dict
import ElmHtml.InternalTypes exposing (ElmHtml, ElmHtml(..), Tagger)
import Json.Decode exposing (decodeString)
import Json.Encode exposing (bool, encode, object, string)
import Test.Html.Query as Query
import Test.Html.Query.Internal as QueryInternal
import Expect exposing (Expectation)


type EventNode msg
    = EventNode Event (QueryInternal.Single msg)


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


{-| Simulates an event on a node

    type Msg
        = Change String

    test "Input produces expected Msg" <|
        \() ->
            Html.input [ onInput Change ] [ ]
                |> Query.fromHtml
                |> Events.simulate (Input "cats")
                |> Expect.expectEvent (Change "cats")

-}
simulate : Event -> Query.Single msg -> EventNode msg
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
                |> Expect.expectEvent (Change "cats")

-}
expectEvent : msg -> EventNode msg -> Expectation
expectEvent msg (EventNode event (QueryInternal.Single showTrace query)) =
    case eventResult (EventNode event (QueryInternal.Single showTrace query)) of
        Err noEvent ->
            Expect.fail noEvent
                |> QueryInternal.failWithQuery showTrace "" query

        Ok foundMsg ->
            foundMsg
                |> Expect.equal msg
                |> QueryInternal.failWithQuery showTrace ("Event.expectEvent: Expected the msg \x1B[32m" ++ toString msg ++ "\x1B[39m from the event \x1B[31m" ++ toString event ++ "\x1B[39m but could not find the event.") query


{-| Returns a Result with the Msg produced by the event simulated on a node

  test "Input produces expected Msg" <|
      \() ->
          Html.input [ onInput Change ] [ ]
              |> Query.fromHtml
              |> Events.simulate (Input "cats")
              |> Events.eventResult
              |> Expect.equal (Ok <| Change "cats")
-}
eventResult : EventNode msg -> Result String msg
eventResult (EventNode event (QueryInternal.Single showTrace query)) =
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
                Err msg

            Ok single ->
                findEvent eventName single
                    |> Result.andThen (\foundEvent -> decodeString foundEvent jsEvent)


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


findEvent : String -> ElmHtml msg -> Result String (Json.Decode.Decoder msg)
findEvent eventName element =
    let
        elementOutput =
            QueryInternal.prettyPrint element

        eventDecoder node =
            node.facts.events
                |> Dict.get eventName
                |> Result.fromMaybe ("Events.expectEvent: The event \x1B[32m" ++ eventName ++ "\x1B[39m does not exist on the found node.\n\n" ++ elementOutput)
    in
        case element of
            TextTag _ ->
                Err ("Found element is a text, which does not produce events, therefore could not simulate " ++ eventName ++ " on it. Text found: " ++ elementOutput)

            NodeEntry node ->
                eventDecoder node

            CustomNode node ->
                eventDecoder node

            MarkdownNode node ->
                eventDecoder node

            NoOp ->
                Err ("Unknown element found. Could not simulate " ++ eventName ++ " on it.")
