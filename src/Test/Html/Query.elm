module Test.Html.Query exposing (Single, Multiple, fromHtml, find, findAll, count)

import Html exposing (Html)
import Test.Html.Query.Selector.Internal as Selector exposing (Selector)
import Test.Html.Query.Internal as Internal exposing (QueryError(..))
import Html.Inert as Inert
import Expect exposing (Expectation)


type alias Single =
    Internal.Single


type alias Multiple =
    Internal.Multiple



-- STARTERS --


fromHtml : Html msg -> Single
fromHtml html =
    Internal.Query (Inert.fromHtml html) []
        |> Internal.Single



-- SELECTORS --


findAll : List Selector -> Single -> Multiple
findAll selectors (Internal.Single query) =
    Internal.FindAll selectors
        |> Internal.prependSelector query
        |> Internal.Multiple


find : List Selector -> Single -> Single
find selectors (Internal.Single query) =
    Internal.Find selectors
        |> Internal.prependSelector query
        |> Internal.Single



-- EXPECTATIONS --


count : (Int -> Expectation) -> Multiple -> Expectation
count expect ((Internal.Multiple query) as multiple) =
    (List.length >> expect >> failWithQuery "Query.count" query)
        |> Internal.multipleToExpectation multiple


failWithQuery : String -> Internal.Query -> Expectation -> Expectation
failWithQuery queryName query expectation =
    case Expect.getFailure expectation of
        Just { given, message } ->
            (Internal.toLines query ++ [ queryName ])
                |> List.map prefixOutputLine
                |> ((::) (addQueryFromHtmlLine query))
                |> String.join "\n\n\n"
                |> (\str -> str ++ "\n\n\n" ++ message)
                |> Expect.fail

        Nothing ->
            expectation


addQueryFromHtmlLine : Internal.Query -> String
addQueryFromHtmlLine query =
    String.join "\n\n"
        [ prefixOutputLine "Query.fromHtml", Internal.toOutputLine query ]


prefixOutputLine : String -> String
prefixOutputLine =
    (++) "▼ "
