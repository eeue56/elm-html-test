module Test.Html.Query.Internal exposing (..)

import Test.Html.Query.Selector.Internal as InternalSelector exposing (Selector, selectorToString)
import Html.Inert as Inert exposing (Node)
import ElmHtml.InternalTypes exposing (ElmHtml)
import ElmHtml.ToString exposing (nodeTypeToString)
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
                    ("Query.find " ++ joinAsList selectorToString selector)
                        |> addHtmlContext node

                FindAll selector ->
                    ("Query.findAll " ++ joinAsList selectorToString selector)
                        |> addHtmlContext node

        selectorStr =
            List.map (selectorQueryToString node) selectors
    in
        starterStr :: selectorStr


toHtmlString : Query -> String
toHtmlString (Query node selectors starter) =
    nodeTypeToString (Inert.toElmHtml node)


selectorQueryToString : Node -> SelectorQuery -> String
selectorQueryToString node selectorQuery =
    case selectorQuery of
        Descendants selectors ->
            ("Query.descendants " ++ joinAsList selectorToString selectors)
                |> addHtmlContext node

        Children selectors ->
            ("Query.children " ++ joinAsList selectorToString selectors)
                |> addHtmlContext node


addHtmlContext : Node -> String -> String
addHtmlContext node str =
    String.join "\n\n" [ str, nodeTypeToString (Inert.toElmHtml node) ]


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
                InternalSelector.queryAll selectors [ elmHtml ]
                    |> verifySingle
                    |> Result.map (\elem -> [ elem ])

            FindAll selectors ->
                Ok (InternalSelector.queryAll selectors [ elmHtml ])


verifySingle : List a -> Result QueryError a
verifySingle list =
    case list of
        [] ->
            Err NoResultsForSingle

        singleton :: [] ->
            Ok singleton

        multiples ->
            Err (MultipleResultsForSingle (List.length multiples))


multipleToExpectation : Multiple -> (List ElmHtml -> Expectation) -> Expectation
multipleToExpectation (Multiple query) check =
    case traverse query of
        Ok list ->
            check list

        Err error ->
            Expect.fail (queryErrorToString query error)


singleToExpectation : Single -> (ElmHtml -> Expectation) -> Expectation
singleToExpectation (Single query) check =
    case Result.andThen verifySingle (traverse query) of
        Ok elem ->
            check elem

        Err error ->
            Expect.fail (queryErrorToString query error)


queryErrorToString : Query -> QueryError -> String
queryErrorToString query error =
    case error of
        NoResultsForSingle ->
            -- TODO include what the query was and what the html was at this point
            "No results found for single query"

        MultipleResultsForSingle resultCount ->
            -- TODO include what the query was and what the html was at this point
            toString resultCount ++ " results found for single query"
