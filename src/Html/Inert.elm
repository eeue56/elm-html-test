module Html.Inert exposing (Node, fromHtml, toElmHtml)

{-| Inert Html - that is, can't do anything with events.
-}

import Html exposing (Html)
import Native.HtmlAsJson
import Json.Decode
import Html exposing (Html)
import ElmHtml.InternalTypes exposing (decodeElmHtml, ElmHtml)


type Node
    = Node (Html Never)


fromHtml : Html msg -> Node
fromHtml html =
    html
        |> Html.map (\_ -> Debug.crash impossibleMessage)
        |> Node


toJson : Html a -> String
toJson =
    Native.HtmlAsJson.toJson


toElmHtml : Node -> ElmHtml
toElmHtml (Node html) =
    case Json.Decode.decodeString decodeElmHtml (toJson html) of
        Ok elmHtml ->
            elmHtml

        Err str ->
            Debug.crash ("Error internally processing HTML for testing - please report this error message as a bug: " ++ str)


impossibleMessage : String
impossibleMessage =
    "An Inert Node fired an event handler. This should never happen! Please report this bug."
