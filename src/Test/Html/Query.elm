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
    Internal.Find (Inert.fromHtml html) criteria
        |> Internal.Single


findAll : List Criteria -> Html msg -> Multiple
findAll criteria html =
    Internal.FindAll (Inert.fromHtml html) criteria
        |> Internal.Multiple



-- SELECTORS --


children : List Criteria -> Single -> Multiple
children criteria (Internal.Single query) =
    Internal.Children criteria
        |> Internal.Selector query
        |> Internal.Multiple


descendants : Criteria -> Single -> Multiple
descendants criteria (Internal.Single query) =
    Internal.Descendants criteria
        |> Internal.Selector query
        |> Internal.Multiple



-- EXPECTATIONS --


count : (Int -> Expectation) -> Multiple -> Expectation
count expect (Internal.Multiple query) =
    -- TODO make this work instead of hardcoding it to 5
    expect 5
        |> failWithQuery query


failWithQuery : Internal.Query -> Expectation -> Expectation
failWithQuery query expectation =
    case Expect.getFailure expectation of
        Just { given, message } ->
            (Internal.queryToString query ++ "\n\n" ++ message)
                |> Expect.fail

        Nothing ->
            expectation
