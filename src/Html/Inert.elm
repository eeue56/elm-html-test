module Html.Inert exposing (Node, fromHtml, empty)

{-| Inert Html - that is, can't do anything with events.
-}

import Html exposing (Html)


type Node
    = Node (Html Never)
    | EmptyNode


fromHtml : Html msg -> Node
fromHtml html =
    html
        |> Html.map (\_ -> Debug.crash impossibleMessage)
        |> Node


empty : Node
empty =
    EmptyNode


impossibleMessage : String
impossibleMessage =
    "An Inert Node fired an event handler. This should never happen! Please report this bug."
