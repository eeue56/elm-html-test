module Html.Inert exposing (Node, fromHtml, toElmHtml, fromElmHtml)

{-| Inert Html - that is, can't do anything with events.
-}

import Html exposing (Html)
import Native.HtmlAsJson
import Json.Decode
import Html exposing (Html)
import ElmHtml.InternalTypes exposing (decodeElmHtml, ElmHtml)


type Node
    = Node ElmHtml


fromHtml : Html msg -> Node
fromHtml html =
    case Json.Decode.decodeString decodeElmHtml (toJson html) of
        Ok elmHtml ->
            Node elmHtml

        Err str ->
            Debug.crash ("Error internally processing HTML for testing - please report this error message as a bug: " ++ str)


fromElmHtml : ElmHtml -> Node
fromElmHtml =
    Node


toJson : Html a -> String
toJson =
    Native.HtmlAsJson.toJson


toElmHtml : Node -> ElmHtml
toElmHtml (Node elmHtml) =
    elmHtml


impossibleMessage : String
impossibleMessage =
    "An Inert Node fired an event handler. This should never happen! Please report this bug."
