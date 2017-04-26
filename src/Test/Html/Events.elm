module Test.Html.Events
    exposing
        ( Event(..)
        , simulate
        )

{-|

This module allows you to simulate events on Html nodes, the Msg generated
by the event is returned so you can test it

@docs Event, simulate

-}

import ElmHtml.InternalTypes exposing (ElmHtml(NodeEntry))
import Json.Decode exposing (decodeString)
import Json.Encode exposing (bool, encode, object, string)
import Native.HtmlAsJson
import Test.Html.Query as Query
import Test.Html.Query.Internal as QueryInternal


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

    import Html
    import Html.Events exposing (onInput)
    import Test.Html.Query as Query
    import Test.Html.Events as Events
    import Test exposing (test)

    type Msg
        = Change String

    test "Input produces expected Msg" <|
        \() ->
            Html.input [ onInput Change ] [ ]
                |> Query.fromHtml
                |> Events.simulate (Input "cats")
                |> Expect.equal (Ok <| Change "cats")

-}
simulate : Event -> Query.Single -> Result String msg
simulate event (QueryInternal.Single showTrace query) =
    let
        ( eventName, jsEvent ) =
            rawEvent event
    in
        QueryInternal.traverse query
            |> Result.andThen (QueryInternal.verifySingle eventName)
            |> Result.mapError (QueryInternal.queryErrorToString query)
            |> Result.andThen (findEvent eventName)
            |> Result.andThen (\decoder -> decodeString decoder jsEvent)


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
    case element of
        NodeEntry node ->
            node.facts.events
                |> Maybe.andThen (getEventDecoder eventName)
                |> Result.fromMaybe ("Could not find a " ++ eventName ++ " event for " ++ QueryInternal.prettyPrint element)

        _ ->
            Err ("Found element is not a common HTML Node, therefore could not get msg for " ++ eventName ++ " on it. Element found: " ++ QueryInternal.prettyPrint element)


getEventDecoder : String -> Json.Decode.Value -> Maybe (Json.Decode.Decoder msg)
getEventDecoder =
    Native.HtmlAsJson.getEventDecoder
