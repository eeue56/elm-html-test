module Html.Inert exposing (Node, attributeName, findFacts, fromElmHtml, fromHtml, toElmHtml)

{-| Inert Html - that is, can't do anything with events.
-}

import ElmHtml.InternalTypes exposing (ElmHtml(..), EventHandler, Facts, Tagger, decodeElmHtml)
import Html exposing (Html)
import Json.Decode
import Native.HtmlAsJson


type Node msg
    = Node (ElmHtml msg)


fromHtml : Html msg -> Node msg
fromHtml html =
    case Json.Decode.decodeValue (decodeElmHtml taggedEventDecoder) (toJson html) of
        Ok elmHtml ->
            Node elmHtml

        Err str ->
            Debug.crash ("Error internally processing HTML for testing - please report this error message as a bug: " ++ str)


fromElmHtml : ElmHtml msg -> Node msg
fromElmHtml =
    Node


{-| Convert a Html node to a Json string
-}
toJson : Html a -> Json.Decode.Value
toJson node =
    Native.HtmlAsJson.toJson node


toElmHtml : Node msg -> ElmHtml msg
toElmHtml (Node elmHtml) =
    elmHtml


findFacts : Html msg -> Maybe (Facts msg)
findFacts node =
    case toElmHtml (fromHtml node) of
        NodeEntry { facts } ->
            Just facts

        CustomNode { facts } ->
            Just facts

        MarkdownNode { facts } ->
            Just facts

        TextTag _ ->
            Nothing

        NoOp ->
            Nothing


impossibleMessage : String
impossibleMessage =
    "An Inert Node fired an event handler. This should never happen! Please report this bug."


attributeToJson : Html.Attribute a -> Json.Decode.Value
attributeToJson attribute =
    Native.HtmlAsJson.attributeToJson attribute


attributeNameDecoder : Json.Decode.Decoder String
attributeNameDecoder =
    Json.Decode.field "key" Json.Decode.string
        |> Json.Decode.andThen
            (\key ->
                if key == "STYLE" then
                    Json.Decode.succeed "style"
                else if key == "ATTR" || key == "ATTR_NS" || key == "EVENT" then
                    Json.Decode.field "realKey" Json.Decode.string
                else
                    Json.Decode.succeed key
            )


attributeName : Html.Attribute a -> String
attributeName attribute =
    case Json.Decode.decodeValue attributeNameDecoder (attributeToJson attribute) of
        Ok name ->
            name

        Err str ->
            Debug.crash ("Error internally processing Html.Attribute for testing - please report this error message as a bug: " ++ str)


{-| Gets the function out of a tagger
-}
taggerFunction : Tagger -> (a -> msg)
taggerFunction tagger =
    Native.HtmlAsJson.taggerFunction tagger


{-| Gets the decoder out of an EventHandler
-}
eventDecoder : EventHandler -> Json.Decode.Decoder msg
eventDecoder eventHandler =
    Native.HtmlAsJson.eventDecoder eventHandler


{-| Applies the taggers over the event handlers to have the complete event decoder
-}
taggedEventDecoder : List Tagger -> EventHandler -> Json.Decode.Decoder msg
taggedEventDecoder taggers eventHandler =
    case taggers of
        [] ->
            eventDecoder eventHandler

        [ tagger ] ->
            Json.Decode.map (taggerFunction tagger) (eventDecoder eventHandler)

        tagger :: taggers ->
            Json.Decode.map (taggerFunction tagger) (taggedEventDecoder taggers eventHandler)
