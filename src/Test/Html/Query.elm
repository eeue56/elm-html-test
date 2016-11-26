module Test.Html.Query exposing (Single, Multiple, fromHtml, find, findAll, count, has, each)

{-|

@docs Single, Multiple, fromHtml

## Querying

@docs find, findAll

## Expecting

@docs count, has, each
-}

import Html exposing (Html)
import Test.Html.Selector.Internal as Selector exposing (Selector, selectorToString)
import Test.Html.Query.Internal as Internal exposing (QueryError(..))
import Html.Inert as Inert
import Expect exposing (Expectation)


{-| TODO
-}
type alias Single =
    Internal.Single


{-| TODO
-}
type alias Multiple =
    Internal.Multiple



-- STARTERS --


{-| TODO
-}
fromHtml : Html msg -> Single
fromHtml html =
    Internal.Query (Inert.fromHtml html) []
        |> Internal.Single



-- SELECTORS --


{-| TODO
-}
findAll : List Selector -> Single -> Multiple
findAll selectors (Internal.Single query) =
    Internal.FindAll selectors
        |> Internal.prependSelector query
        |> Internal.Multiple


{-| TODO
-}
find : List Selector -> Single -> Single
find selectors (Internal.Single query) =
    Internal.Find selectors
        |> Internal.prependSelector query
        |> Internal.Single



-- EXPECTATIONS --


{-| TODO
-}
count : (Int -> Expectation) -> Multiple -> Expectation
count expect ((Internal.Multiple query) as multiple) =
    (List.length >> expect >> failWithQuery "Query.count" query)
        |> Internal.multipleToExpectation multiple


{-| TODO
-}
has : List Selector -> Single -> Expectation
has selectors (Internal.Single query) =
    Internal.has selectors query
        |> failWithQuery ("Query.has " ++ Internal.joinAsList selectorToString selectors) query


{-| TODO
-}
each : (Single -> Expectation) -> Multiple -> Expectation
each check query =
    Internal.expectAll check query



-- HELPERS --


failWithQuery : String -> Internal.Query -> Expectation -> Expectation
failWithQuery queryName query expectation =
    case Expect.getFailure expectation of
        Just { given, message } ->
            (Internal.toLines query ++ [ queryName ])
                |> List.map prefixOutputLine
                |> ((::) (addQueryFromHtmlLine query))
                |> String.join "\n\n\n"
                |> (\str -> str ++ "\n\n" ++ message)
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
