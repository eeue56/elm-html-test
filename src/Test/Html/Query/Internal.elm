module Test.Html.Query.Internal exposing (..)

import Test.Html.Selector.Internal as InternalSelector exposing (Selector, selectorToString)
import Html.Inert as Inert exposing (Node)
import ElmHtml.InternalTypes exposing (ElmHtml(..))
import ElmHtml.ToString exposing (nodeTypeToString)
import Expect exposing (Expectation)
import Array


{-| Note: the selectors are stored in reverse order for better prepending perf.
-}
type Query
    = Query Inert.Node (List SelectorQuery)


type SelectorQuery
    = Find (List Selector)
    | FindAll (List Selector)
      -- First and Index are separate so we can report Query.first in error messages
    | First
    | Index Int


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
    let
        bailOut result =
            -- Bail out early so the last error message the user
            -- sees is Query.find rather than something like
            -- Query.has, to reflect how we didn't make it that far.
            String.join "\n\n\n✗ " [ result, expectationFailure ] :: results

        recurse rest result =
            toLinesHelp expectationFailure node rest queryName (result :: results)
    in
        case selectorQueries of
            [] ->
                String.join "\n\n" [ queryName, expectationFailure ] :: results

            selectorQuery :: rest ->
                case selectorQuery of
                    FindAll selectors ->
                        let
                            elements =
                                node
                                    |> Inert.toElmHtml
                                    |> getChildren
                                    |> InternalSelector.queryAll selectors
                        in
                            ("Query.findAll " ++ joinAsList selectorToString selectors)
                                |> withHtmlContext (getHtmlContext elements)
                                |> recurse rest

                    Find selectors ->
                        let
                            elements =
                                node
                                    |> Inert.toElmHtml
                                    |> getChildren
                                    |> InternalSelector.queryAll selectors

                            result =
                                ("Query.find " ++ joinAsList selectorToString selectors)
                                    |> withHtmlContext (getHtmlContext elements)
                        in
                            if List.length elements == 1 then
                                recurse rest result
                            else
                                bailOut result

                    First ->
                        let
                            elements =
                                node
                                    |> Inert.toElmHtml
                                    |> getChildren
                                    |> List.head
                                    |> Maybe.map (\elem -> [ elem ])
                                    |> Maybe.withDefault []

                            result =
                                "Query.first"
                                    |> withHtmlContext (getHtmlContext elements)
                        in
                            if List.length elements == 1 then
                                recurse rest result
                            else
                                bailOut result

                    Index index ->
                        let
                            elements =
                                node
                                    |> Inert.toElmHtml
                                    |> getChildren
                                    |> Array.fromList
                                    |> Array.get index
                                    |> Maybe.map (\elem -> [ elem ])
                                    |> Maybe.withDefault []

                            result =
                                ("Query.index " ++ toString index)
                                    |> withHtmlContext (getHtmlContext elements)
                        in
                            if List.length elements == 1 then
                                recurse rest result
                            else
                                bailOut result


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
traverseSelector selectorQuery elmHtmlList =
    case selectorQuery of
        Find selectors ->
            elmHtmlList
                |> List.concatMap getChildren
                |> InternalSelector.queryAll selectors
                |> verifySingle
                |> Result.map (\elem -> [ elem ])

        FindAll selectors ->
            elmHtmlList
                |> List.concatMap getChildren
                |> InternalSelector.queryAll selectors
                |> Ok

        First ->
            elmHtmlList
                |> List.concatMap getChildren
                |> List.head
                |> Maybe.map (\elem -> Ok [ elem ])
                |> Maybe.withDefault (Err NoResultsForSingle)

        Index index ->
            elmHtmlList
                |> List.concatMap getChildren
                |> Array.fromList
                |> Array.get index
                |> Maybe.map (\elem -> Ok [ elem ])
                |> Maybe.withDefault (Err NoResultsForSingle)


getChildren : ElmHtml -> List ElmHtml
getChildren elmHtml =
    case elmHtml of
        NodeEntry { children } ->
            children

        _ ->
            []


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
