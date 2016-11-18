module Test.Html.Query.Internal exposing (..)

import Test.Html.Query.Selector.Internal as InternalSelector exposing (Selector, selectorToString)
import Html.Inert as Inert exposing (Node)
import ElmHtml.InternalTypes exposing (ElmHtml)
import ElmHtml.Query


{-| Note: the selectors are stored in reverse order for better prepending perf.
-}
type Query
    = Query Inert.Node (List SelectorQuery) StarterQuery


type StarterQuery
    = Find (List Selector)
    | FindAll (List Selector)


type SelectorQuery
    = Descendants (List Selector)
    | Children (List Selector)


type Single
    = Single Query


type Multiple
    = Multiple Query


toLines : Query -> List String
toLines (Query node selectors starter) =
    let
        starterStr =
            case starter of
                Find selector ->
                    "Query.find " ++ joinAsList selectorToString selector

                FindAll selector ->
                    "Query.findAll " ++ joinAsList selectorToString selector

        selectorStr =
            List.map (selectorQueryToString node) selectors
    in
        starterStr :: selectorStr


selectorQueryToString : Node -> SelectorQuery -> String
selectorQueryToString node selectorQuery =
    case selectorQuery of
        Descendants selectors ->
            "Query.descendants " ++ joinAsList selectorToString selectors

        Children selectors ->
            "Query.children " ++ joinAsList selectorToString selectors


joinAsList : (a -> String) -> List a -> String
joinAsList toStr list =
    if List.isEmpty list then
        "[]"
    else
        "[ " ++ String.join ", " (List.map toStr list) ++ " ]"


prependSelector : Query -> SelectorQuery -> Query
prependSelector (Query node selectors starter) selector =
    Query node (selector :: selectors) starter



-- REPRO NOTE: replace this implementation with Debug.crash "blah" to MVar compiler


traverse : Query -> List ElmHtml
traverse (Query node selectors starter) =
    let
        elmHtml =
            Inert.toElmHtml node
    in
        case starter of
            Find selector ->
                []

            FindAll selector ->
                []
