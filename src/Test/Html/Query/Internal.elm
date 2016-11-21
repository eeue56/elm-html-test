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
    List.map (selectorQueryToString node) (List.reverse selectors)


toOutputLine : Query -> String
toOutputLine (Query node selectors) =
    htmlPrefix ++ nodeTypeToString (Inert.toElmHtml node)


selectorQueryToString : Node -> SelectorQuery -> String
selectorQueryToString node selectorQuery =
    let
        ( str, htmlStr ) =
            case selectorQuery of
                FindAll selectors ->
                    ( "Query.findAll " ++ joinAsList selectorToString selectors
                    , getHtmlContext (InternalSelector.queryAll selectors [ Inert.toElmHtml node ])
                    )

                Find selectors ->
                    ( "Query.find " ++ joinAsList selectorToString selectors
                    , getHtmlContext (InternalSelector.queryAll selectors [ Inert.toElmHtml node ])
                    )
    in
        String.join "\n\n"
            [ str, htmlStr ]


getHtmlContext : List ElmHtml -> String
getHtmlContext elmHtmlList =
    elmHtmlList
        |> List.indexedMap (\index elmHtml -> htmlPrefix ++ toString (index + 1) ++ ") " ++ nodeTypeToString elmHtml)
        |> String.join "\n\n"


joinAsList : (a -> String) -> List a -> String
joinAsList toStr list =
    if List.isEmpty list then
        "[]"
    else
        "[ " ++ String.join ", " (List.map toStr list) ++ " ]"


htmlPrefix : String
htmlPrefix =
    "    "


prependSelector : Query -> SelectorQuery -> Query
prependSelector (Query node selectors) selector =
    Query node (selector :: selectors)



-- REPRO NOTE: replace this implementation with Debug.crash "blah" to MVar compiler


traverse : Query -> Result QueryError (List ElmHtml)
traverse (Query node selectorQueries) =
    traverseSelectors selectorQueries [ Inert.toElmHtml node ]


traverseSelectors : List SelectorQuery -> List ElmHtml -> Result QueryError (List ElmHtml)
traverseSelectors selectorQueries elmHtmlList =
    List.foldr
        (traverseSelector >> Result.andThen)
        (Ok elmHtmlList)
        selectorQueries


traverseSelector : SelectorQuery -> List ElmHtml -> Result QueryError (List ElmHtml)
traverseSelector selectorQuery elmHtml =
    case selectorQuery of
        Find selectors ->
            InternalSelector.queryAll selectors elmHtml
                |> verifySingle
                |> Result.map (\elem -> [ elem ])

        FindAll selectors ->
            InternalSelector.queryAll selectors elmHtml
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


expectAll : (Single -> Expectation) -> Multiple -> Expectation
expectAll check (Multiple query) =
    case traverse query of
        Ok list ->
            expectAllHelp check list

        Err error ->
            Expect.fail (queryErrorToString query error)


expectAllHelp : (Single -> Expectation) -> List ElmHtml -> Expectation
expectAllHelp check list =
    case list of
        [] ->
            Expect.pass

        elmHtml :: rest ->
            let
                outcome =
                    Query (Inert.fromElmHtml elmHtml) []
                        |> Single
                        |> check
            in
                if outcome == Expect.pass then
                    expectAllHelp check rest
                else
                    outcome


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


has : List Selector -> Query -> Expectation
has selectors query =
    case traverse query of
        Ok elmHtmlList ->
            if List.isEmpty (InternalSelector.queryAll selectors elmHtmlList) then
                selectors
                    |> List.map (showSelectorOutcome elmHtmlList)
                    |> String.join "\n"
                    |> Expect.fail
            else
                Expect.pass

        Err error ->
            Expect.fail (queryErrorToString query error)


showSelectorOutcome : List ElmHtml -> Selector -> String
showSelectorOutcome elmHtmlList selector =
    let
        outcome =
            if List.isEmpty (InternalSelector.queryAll [ selector ] elmHtmlList) then
                "✗"
            else
                "✓"
    in
        String.join " " [ outcome, selectorToString selector ]
