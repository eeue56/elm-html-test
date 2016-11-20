module Test.Html.Query.Internal exposing (..)

import Test.Html.Query.Selector.Internal as InternalSelector exposing (Selector, selectorToString)
import Html.Inert as Inert exposing (Node)
import ElmHtml.InternalTypes exposing (ElmHtml)
import ElmHtml.ToString exposing (nodeTypeToString)
import Expect exposing (Expectation)


{-| Note: the selectors are stored in reverse order for better prepending perf.
-}
type Query
    = Query Inert.Node (List SelectorQuery)


type SelectorQuery
    = Find (List Selector)
    | FindAll (List Selector)


type Single
    = Single Query


type Multiple
    = Multiple Query


type QueryError
    = NoResultsForSingle
    | MultipleResultsForSingle Int


toLines : Query -> List String
toLines (Query node selectors) =
    List.map (selectorQueryToString node) selectors


toHtmlString : Query -> String
toHtmlString (Query node selectors) =
    nodeTypeToString (Inert.toElmHtml node)


selectorQueryToString : Node -> SelectorQuery -> String
selectorQueryToString node selectorQuery =
    case selectorQuery of
        Find selectors ->
            ("Query.find " ++ joinAsList selectorToString selectors)
                |> addHtmlContext node (InternalSelector.queryAll selectors)

        FindAll selectors ->
            ("Query.findAll " ++ joinAsList selectorToString selectors)
                |> addHtmlContext node (InternalSelector.queryAll selectors)


addHtmlContext : Node -> (List ElmHtml -> List ElmHtml) -> String -> String
addHtmlContext node transform str =
    let
        htmlStr =
            transform [ Inert.toElmHtml node ]
                |> List.map nodeTypeToString
                |> String.join "\n"
    in
        String.join "\n\n" [ str, htmlStr ]


joinAsList : (a -> String) -> List a -> String
joinAsList toStr list =
    if List.isEmpty list then
        "[]"
    else
        "[ " ++ String.join ", " (List.map toStr list) ++ " ]"


prependSelector : Query -> SelectorQuery -> Query
prependSelector (Query node selectors) selector =
    Query node (selector :: selectors)


traverse : Query -> Result QueryError (List ElmHtml)
traverse (Query node selectorQueries) =
    node
        |> Inert.toElmHtml
        |> traverseSelectors selectorQueries


traverseSelectors : List SelectorQuery -> ElmHtml -> Result QueryError (List ElmHtml)
traverseSelectors selectorQueries elmHtml =
    List.foldl
        (traverseSelector >> Result.andThen)
        (Ok [ elmHtml ])
        selectorQueries


traverseSelector : SelectorQuery -> List ElmHtml -> Result QueryError (List ElmHtml)
traverseSelector selectorQuery elmHtmlList =
    case selectorQuery of
        Find selectors ->
            InternalSelector.queryAll selectors elmHtmlList
                |> verifySingle
                |> Result.map (\elem -> [ elem ])

        FindAll selectors ->
            InternalSelector.queryAll selectors elmHtmlList
                |> Ok


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
