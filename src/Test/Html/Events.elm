module Test.Html.Events
    exposing
        ( simulate
        )

{-|

@docs simulate
-}

import ElmHtml.InternalTypes exposing (ElmHtml(NodeEntry))
import Json.Decode exposing (decodeString, decodeValue, field, string)
import Native.HtmlAsJson
import Test.Html.Query as Query
import Test.Html.Query.Internal as QueryInternal


getEventDecoder : String -> Json.Decode.Value -> Maybe (Json.Decode.Decoder msg)
getEventDecoder =
    Native.HtmlAsJson.getEventDecoder


{-| Gets a Msg produced by a node when an event is triggered.

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
                |> Events.simulate "input" "{\"target\": {\"value\": \"cats\"}}"
                |> Expect.equal (Ok <| Change "cats")

-}
simulate : String -> String -> Query.Single -> Result String msg
simulate eventName event (QueryInternal.Single showTrace query) =
    QueryInternal.traverse query
        |> Result.andThen (QueryInternal.verifySingle eventName)
        |> Result.mapError (QueryInternal.queryErrorToString query)
        |> Result.andThen (findEvent eventName)
        |> Result.andThen (\decoder -> decodeString decoder event)


findEvent : String -> ElmHtml -> Result String (Json.Decode.Decoder msg)
findEvent eventName element =
    case element of
        NodeEntry node ->
            node.facts.events
                |> Maybe.andThen (getEventDecoder eventName)
                |> Result.fromMaybe ("Could not find a " ++ eventName ++ " event for " ++ QueryInternal.prettyPrint element)

        _ ->
            Err ("Found element is not a common HTML Node, therefore could not get msg for " ++ eventName ++ " on it. Element found: " ++ QueryInternal.prettyPrint element)
