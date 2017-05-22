module Test.Html.Event
    exposing
        ( Event
        , simulate
        , expect
        , toResult
        , click
        , doubleClick
        , mouseDown
        , mouseUp
        , mouseEnter
        , mouseLeave
        , mouseOver
        , mouseOut
        , input
        , check
        , submit
        , blur
        , focus
        )

{-| This module allows you to simulate events on Html nodes, the Msg generated
by the event is returned so you can test it.


## Simulating Events

@docs Event, simulate, expect, toResult


## Event Builders

@docs click, doubleClick, mouseDown, mouseUp, mouseEnter, mouseLeave, mouseOver, mouseOut, input, check, submit, blur, focus

-}

import Dict
import ElmHtml.InternalTypes exposing (ElmHtml, ElmHtml(..), Tagger)
import Json.Decode exposing (decodeString)
import Json.Encode exposing (bool, encode, object, string)
import Test.Html.Query as Query
import Test.Html.Query.Internal as QueryInternal
import Expect exposing (Expectation)


{-| A simulated event.

See [`simulate`](#simulate).

-}
type Event msg
    = Event ( String, String ) (QueryInternal.Single msg)


{-| Simulate an event on a node.

    import Test.Html.Event as Event

    type Msg
        = Change String


    test "Input produces expected Msg" <|
        \() ->
            Html.input [ onInput Change ] [ ]
                |> Query.fromHtml
                |> Event.simulate (Event.input "cats")
                |> Event.expect (Change "cats")

-}
simulate : ( String, String ) -> Query.Single msg -> Event msg
simulate event single =
    Event event single


{-| Passes if the given message is triggered by the simulated event.

    import Test.Html.Event as Event

    type Msg
        = Change String


    test "Input produces expected Msg" <|
        \() ->
            Html.input [ onInput Change ] [ ]
                |> Query.fromHtml
                |> Event.simulate (Event.input "cats")
                |> Event.expect (Change "cats")

-}
expect : msg -> Event msg -> Expectation
expect msg (Event event (QueryInternal.Single showTrace query)) =
    case toResult (Event event (QueryInternal.Single showTrace query)) of
        Err noEvent ->
            Expect.fail noEvent
                |> QueryInternal.failWithQuery showTrace "" query

        Ok foundMsg ->
            foundMsg
                |> Expect.equal msg
                |> QueryInternal.failWithQuery showTrace ("Event.expectEvent: Expected the msg \x1B[32m" ++ toString msg ++ "\x1B[39m from the event \x1B[31m" ++ toString event ++ "\x1B[39m but could not find the event.") query


{-| Returns a Result with the Msg produced by the event simulated on a node.
Note that Event.expect gives nicer messages; this is generally more useful
when testing that an event handler is *not* present.

    import Test.Html.Event as Event


    test "Input produces expected Msg" <|
        \() ->
            Html.input [ onInput Change ] [ ]
                |> Query.fromHtml
                |> Event.simulate (Event.input "cats")
                |> Event.toResult
                |> Expect.equal (Ok (Change "cats"))

-}
toResult : Event msg -> Result String msg
toResult (Event ( eventName, jsEvent ) (QueryInternal.Single showTrace query)) =
    let
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



-- EVENTS --


click : ( String, String )
click =
    ( "click", "{}" )


doubleClick : ( String, String )
doubleClick =
    ( "dblclick", "{}" )


mouseDown : ( String, String )
mouseDown =
    ( "mousedown", "{}" )


mouseUp : ( String, String )
mouseUp =
    ( "mouseup", "{}" )


mouseEnter : ( String, String )
mouseEnter =
    ( "mouseenter", "{}" )


mouseLeave : ( String, String )
mouseLeave =
    ( "mouseleave", "{}" )


mouseOver : ( String, String )
mouseOver =
    ( "mouseover", "{}" )


mouseOut : ( String, String )
mouseOut =
    ( "mouseout", "{}" )


input : String -> ( String, String )
input value =
    ( "input"
    , object
        [ ( "target"
          , object [ ( "value", string value ) ]
          )
        ]
        |> encode 0
    )


check : Bool -> ( String, String )
check checked =
    ( "change"
    , object
        [ ( "target"
          , object [ ( "checked", bool checked ) ]
          )
        ]
        |> encode 0
    )


submit : ( String, String )
submit =
    ( "submit", "{}" )


blur : ( String, String )
blur =
    ( "blur", "{}" )


focus : ( String, String )
focus =
    ( "focus", "{}" )



-- INTERNAL --


findEvent : String -> ElmHtml msg -> Result String (Json.Decode.Decoder msg)
findEvent eventName element =
    let
        elementOutput =
            QueryInternal.prettyPrint element

        eventDecoder node =
            node.facts.events
                |> Dict.get eventName
                |> Result.fromMaybe ("Event.expectEvent: The event " ++ eventName ++ " does not exist on the found node.\n\n" ++ elementOutput)
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
