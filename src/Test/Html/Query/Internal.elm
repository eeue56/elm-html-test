module Test.Html.Query.Internal exposing (..)

import Test.Html.Query.Selector.Internal as InternalSelector exposing (Selector, selectorToString)
import Html.Inert as Inert exposing (Node)
import ElmHtml.InternalTypes exposing (ElmHtml)
import Expect exposing (Expectation)


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


type QueryError
    = NoResultsForSingle
    | MultipleResultsForSingle Int


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


traverse : Query -> Result QueryError (List ElmHtml)
traverse (Query node selectors starter) =
    let
        elmHtml =
            Inert.toElmHtml node
    in
        case starter of
            Find selectors ->
                case InternalSelector.queryAll selectors [ elmHtml ] of
                    [] ->
                        Err NoResultsForSingle

                    singleton :: [] ->
                        Ok [ singleton ]

                    multiples ->
                        Err (MultipleResultsForSingle (List.length multiples))

            FindAll selectors ->
                Ok (InternalSelector.queryAll selectors [ elmHtml ])


toExpectation : Query -> (List ElmHtml -> Expectation) -> Expectation
toExpectation query checkResults =
    case traverse query of
        Ok results ->
            checkResults results

        Err NoResultsForSingle ->
            -- TODO include what the query was and what the html was at this point
            Expect.fail "No results found for single query"

        Err (MultipleResultsForSingle resultCount) ->
            -- TODO include what the query was and what the html was at this point
            Expect.fail (toString resultCount ++ " results found for single query")
