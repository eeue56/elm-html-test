module Test.Html.Query.Internal exposing (..)

import Test.Html.Selector.Internal as InternalSelector exposing (Selector, selectorToString)
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


toLines : String -> Query -> String -> List String
toLines expectationFailure (Query node selectors) queryName =
    toLinesHelp expectationFailure node (List.reverse selectors) queryName []
        |> List.reverse


toOutputLine : Query -> String
toOutputLine (Query node selectors) =
    htmlPrefix ++ nodeTypeToString (Inert.toElmHtml node)


toLinesHelp : String -> Node -> List SelectorQuery -> String -> List String -> List String
toLinesHelp expectationFailure node selectorQueries queryName results =
    case selectorQueries of
        [] ->
            String.join "\n\n" [ queryName, expectationFailure ] :: results

        selectorQuery :: rest ->
            case selectorQuery of
                FindAll selectors ->
                    let
                        result =
                            withHtmlContext
                                (getHtmlContext (InternalSelector.queryAll selectors [ Inert.toElmHtml node ]))
                                ("Query.findAll " ++ joinAsList selectorToString selectors)
                    in
                        toLinesHelp expectationFailure node rest queryName (result :: results)

                Find selectors ->
                    let
                        elements =
                            InternalSelector.queryAll selectors [ Inert.toElmHtml node ]

                        result =
                            withHtmlContext
                                (getHtmlContext elements)
                                ("Query.find " ++ joinAsList selectorToString selectors)
                    in
                        if List.length elements == 1 then
                            toLinesHelp expectationFailure node rest queryName (result :: results)
                        else
                            -- Bail out early so the last error message the user
                            -- sees is Query.find rather than something like
                            -- Query.has, to reflect how we didn't make it that far.
                            String.join "\n\n\n✗ " [ result, expectationFailure ] :: results


withHtmlContext : String -> String -> String
withHtmlContext htmlStr str =
    String.join "\n\n" [ str, htmlStr ]


getHtmlContext : List ElmHtml -> String
getHtmlContext elmHtmlList =
    if List.isEmpty elmHtmlList then
        "0 matches found for this query."
    else
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
            "Query.find always expects to find 1 element, but it found 0 instead."

        MultipleResultsForSingle resultCount ->
            "Query.find always expects to find 1 element, but it found "
                ++ toString resultCount
                ++ " instead.\n\n\nHINT: If you actually expected "
                ++ toString resultCount
                ++ " elements, use Query.findAll instead of Query.find."


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
        String.join " " [ outcome, "has", selectorToString selector ]
