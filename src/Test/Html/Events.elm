module Test.Html.Events
    exposing
        ( trigger
        )

{-|

@docs trigger
-}

import ElmHtml.InternalTypes exposing (ElmHtml(NodeEntry))
import Json.Decode exposing (decodeString, decodeValue, field, string)
import Native.HtmlAsJson
import Test.Html.Query as Query
import Test.Html.Query.Internal as QueryInternal


getEventDecoder : String -> Json.Decode.Value -> Maybe (Json.Decode.Decoder msg)
getEventDecoder =
    Native.HtmlAsJson.getEventDecoder


{-| Trigger events
-}
trigger : String -> String -> Query.Single -> Result String msg
trigger name event (QueryInternal.Single showTrace query) =
    QueryInternal.traverse query
        |> Result.andThen (QueryInternal.verifySingle <| "Trigger " ++ name)
        |> Result.mapError (QueryInternal.queryErrorToString query)
        |> Result.andThen (findEvent name)
        |> Result.andThen (\decoder -> decodeString decoder event)


findEvent : String -> ElmHtml -> Result String (Json.Decode.Decoder msg)
findEvent name element =
    case element of
        NodeEntry node ->
            node.facts.events
                |> Maybe.andThen (getEventDecoder name)
                |> Result.fromMaybe ("Could not find a " ++ name ++ " event for " ++ QueryInternal.prettyPrint element)

        _ ->
            Err ("Found element is not a common HTML Node, therefore could not trigger " ++ name ++ " on it. Element found: " ++ QueryInternal.prettyPrint element)
