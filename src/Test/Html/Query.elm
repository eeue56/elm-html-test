module Test.Html.Query exposing (Single, Multiple, find, findAll, children, descendants, count)

import Html exposing (Html)
import Test.Html.Query.Criteria as Criteria exposing (Criteria)
import Test.Html.Query.Internal as Internal
import Html.Inert as Inert
import Expect exposing (Expectation)


type alias Single =
    Internal.Single


type alias Multiple =
    Internal.Multiple



-- STARTERS --


find : List Criteria -> Html msg -> Single
find criteria html =
    Internal.Find criteria
        |> Internal.Query (Inert.fromHtml html) []
        |> Internal.Single


findAll : List Criteria -> Html msg -> Multiple
findAll criteria html =
    Internal.FindAll criteria
        |> Internal.Query (Inert.fromHtml html) []
        |> Internal.Multiple



-- SELECTORS --


children : List Criteria -> Single -> Multiple
children criteria (Internal.Single query) =
    Internal.Children criteria
        |> Internal.prependSelector query
        |> Internal.Multiple


descendants : List Criteria -> Single -> Multiple
descendants criteria (Internal.Single query) =
    Internal.Descendants criteria
        |> Internal.prependSelector query
        |> Internal.Multiple



-- EXPECTATIONS --


count : (Int -> Expectation) -> Multiple -> Expectation
count expect (Internal.Multiple query) =
    query
        |> Internal.traverse
        |> List.length
        |> expect
        |> failWithQuery "Query.count" query


failWithQuery : String -> Internal.Query -> Expectation -> Expectation
failWithQuery queryName query expectation =
    case Expect.getFailure expectation of
        Just { given, message } ->
            (queryName :: Internal.toLines query)
                |> List.reverse
                |> List.map prefixOutputLine
                |> String.join "\n\n"
                |> (\str -> str ++ "\n\n\n" ++ message)
                |> Expect.fail

        Nothing ->
            expectation


prefixOutputLine : String -> String
prefixOutputLine =
    (++) "▼ "
