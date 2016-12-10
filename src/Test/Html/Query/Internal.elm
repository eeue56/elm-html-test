module Test.Html.Query.Internal exposing (..)

import Test.Html.Selector.Internal as InternalSelector exposing (Selector, selectorToString)
import Html.Inert as Inert exposing (Node)
import ElmHtml.InternalTypes exposing (ElmHtml(..))
import ElmHtml.ToString exposing (nodeToStringWithOptions)
import Expect exposing (Expectation)


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


{-| The Bool is `showTrace` - whether to show the Query.fromHtml trace at
the beginning of the error message.

We need to track this so that Query.each can turn it off. Otherwise you get
fromHtml printed twice - once at the very top, then again for the nested
expectation that Query.each delegated to.
-}
type Single
    = Single Bool Query


{-| The Bool is `showTrace` - see `Single` for more info.
-}
type Multiple
    = Multiple Bool Query


type QueryError
    = NoResultsForSingle String
    | MultipleResultsForSingle String Int


toLines : String -> Query -> String -> List String
toLines expectationFailure (Query node selectors) queryName =
    toLinesHelp expectationFailure [ Inert.toElmHtml node ] (List.reverse selectors) queryName []
        |> List.reverse


prettyPrint : ElmHtml -> String
prettyPrint =
    nodeToStringWithOptions { indent = 4, newLines = True }

toOutputLine : Query -> String
toOutputLine (Query node selectors) =
    prettyPrint (Inert.toElmHtml node)


toLinesHelp : String -> List ElmHtml -> List SelectorQuery -> String -> List String -> List String
toLinesHelp expectationFailure elmHtmlList selectorQueries queryName results =
    let
        bailOut result =
            -- Bail out early so the last error message the user
            -- sees is Query.find rather than something like
            -- Query.has, to reflect how we didn't make it that far.
            String.join "\n\n\n✗ " [ result, expectationFailure ] :: results

        recurse newElmHtmlList rest result =
            toLinesHelp
                expectationFailure
                newElmHtmlList
                rest
                queryName
                (result :: results)
    in
        case selectorQueries of
            [] ->
                String.join "\n\n" [ queryName, expectationFailure ] :: results

            selectorQuery :: rest ->
                case selectorQuery of
                    FindAll selectors ->
                        let
                            elements =
                                elmHtmlList
                                    |> List.concatMap getChildren
                                    |> InternalSelector.queryAll selectors
                        in
                            ("Query.findAll " ++ joinAsList selectorToString selectors)
                                |> withHtmlContext (getHtmlContext elements)
                                |> recurse elements rest

                    Find selectors ->
                        let
                            elements =
                                elmHtmlList
                                    |> List.concatMap getChildren
                                    |> InternalSelector.queryAll selectors

                            result =
                                ("Query.find " ++ joinAsList selectorToString selectors)
                                    |> withHtmlContext (getHtmlContext elements)
                        in
                            if List.length elements == 1 then
                                recurse elements rest result
                            else
                                bailOut result

                    First ->
                        let
                            elements =
                                elmHtmlList
                                    |> List.head
                                    |> Maybe.map (\elem -> [ elem ])
                                    |> Maybe.withDefault []

                            result =
                                "Query.first"
                                    |> withHtmlContext (getHtmlContext elements)
                        in
                            if List.length elements == 1 then
                                recurse elements rest result
                            else
                                bailOut result

                    Index index ->
                        let
                            elements =
                                elmHtmlList
                                    |> getElementAt index

                            result =
                                ("Query.index " ++ toString index)
                                    |> withHtmlContext (getHtmlContext elements)
                        in
                            if List.length elements == 1 then
                                recurse elements rest result
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
            |> List.indexedMap (\index elmHtml -> htmlPrefix ++ toString (index + 1) ++ ")\n\n" ++ prettyPrint elmHtml)
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


{-| This is a more efficient implementation of the following:

list
    |> Array.fromList
    |> Array.get index
    |> Maybe.map (\elem -> [ elem ])
    |> Maybe.withDefault []

It also supports wraparound via negative indeces, e.g. passing -1 for an index
gets you the last element.
-}
getElementAt : Int -> List a -> List a
getElementAt index list =
    let
        length =
            List.length list
    in
        -- Avoid attempting % 0
        if length == 0 then
            []
        else
            -- Support wraparound, e.g. passing -1 to get the last element.
            getElementAtHelp (index % length) list


getElementAtHelp : Int -> List a -> List a
getElementAtHelp index list =
    case list of
        [] ->
            []

        first :: rest ->
            if index == 0 then
                [ first ]
            else
                getElementAtHelp (index - 1) rest


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
                |> verifySingle "Query.find"
                |> Result.map (\elem -> [ elem ])

        FindAll selectors ->
            elmHtmlList
                |> List.concatMap getChildren
                |> InternalSelector.queryAll selectors
                |> Ok

        First ->
            elmHtmlList
                |> List.head
                |> Maybe.map (\elem -> Ok [ elem ])
                |> Maybe.withDefault (Err (NoResultsForSingle "Query.first"))

        Index index ->
            let
                elements =
                    elmHtmlList
                        |> getElementAt index
            in
                if List.length elements == 1 then
                    Ok elements
                else
                    Err (NoResultsForSingle ("Query.index " ++ toString index))


getChildren : ElmHtml -> List ElmHtml
getChildren elmHtml =
    case elmHtml of
        NodeEntry { children } ->
            children

        _ ->
            []


isElement : ElmHtml -> Bool
isElement elmHtml =
    case elmHtml of
        NodeEntry _ ->
            True

        _ ->
            False


verifySingle : String -> List a -> Result QueryError a
verifySingle queryName list =
    case list of
        [] ->
            Err (NoResultsForSingle queryName)

        singleton :: [] ->
            Ok singleton

        multiples ->
            Err (MultipleResultsForSingle queryName (List.length multiples))


expectAll : (Single -> Expectation) -> Query -> Expectation
expectAll check query =
    case traverse query of
        Ok list ->
            expectAllHelp 0 check list

        Err error ->
            Expect.fail (queryErrorToString query error)


expectAllHelp : Int -> (Single -> Expectation) -> List ElmHtml -> Expectation
expectAllHelp successes check list =
    case list of
        [] ->
            Expect.pass

        elmHtml :: rest ->
            let
                expectation =
                    Query (Inert.fromElmHtml elmHtml) []
                        |> Single False
                        |> check
            in
                case Expect.getFailure expectation of
                    Just { given, message } ->
                        let
                            prefix =
                                if successes > 0 then
                                    "Element #" ++ (toString (successes + 1)) ++ " failed this test:"
                                else
                                    "The first element failed this test:"
                        in
                            [ prefix, message ]
                                |> String.join "\n\n"
                                |> Expect.fail

                    Nothing ->
                        expectAllHelp (successes + 1) check rest


multipleToExpectation : Multiple -> (List ElmHtml -> Expectation) -> Expectation
multipleToExpectation (Multiple _ query) check =
    case traverse query of
        Ok list ->
            check list

        Err error ->
            Expect.fail (queryErrorToString query error)


queryErrorToString : Query -> QueryError -> String
queryErrorToString query error =
    case error of
        NoResultsForSingle queryName ->
            queryName ++ " always expects to find 1 element, but it found 0 instead."

        MultipleResultsForSingle queryName resultCount ->
            queryName
                ++ " always expects to find 1 element, but it found "
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
