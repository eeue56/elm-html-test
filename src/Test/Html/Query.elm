module Test.Html.Query exposing (Single, Multiple, fromHtml, find, findAll, first, index, count, has, each)

{-|

@docs Single, Multiple, fromHtml

## Querying

@docs find, findAll, first, index

## Expecting

@docs count, has, each
-}

import Html exposing (Html)
import Test.Html.Selector.Internal as Selector exposing (Selector, selectorToString)
import Test.Html.Query.Internal as Internal exposing (QueryError(..))
import Html.Inert as Inert
import Expect exposing (Expectation)


{-| A query that expects to find exactly one element.

Contrast with [`Multiple`](#Multiple).
-}
type alias Single =
    Internal.Single


{-| A query that may find any number of elements, including zero.

Contrast with [`Single`](#Single).
-}
type alias Multiple =
    Internal.Multiple


{-| Translate a `Html` value into a `Single` query. This is how queries
typically begin.

    import Html
    import Query
    import Test exposing (test)
    import Test.Html.Selector exposing (text)


    test "Button has the expected text" <|
        \() ->
            Html.button [] [ Html.text "I'm a button!" ]
                |> Query.fromHtml
                |> Query.has [ text "I'm a button!" ]
-}
fromHtml : Html msg -> Single
fromHtml html =
    Internal.Query (Inert.fromHtml html) []
        |> Internal.Single



-- TRAVERSAL --


{-| Find the descendant elements which match all the given selectors.

    import Html exposing (div, ul, li)
    import Html.Attributes exposing (class)
    import Query
    import Test exposing (test)
    import Test.Html.Selector exposing (tag)


    test "The list has three items" <|
        \() ->
            div []
                [ ul [ class "items active" ]
                    [ li [] [ text "first item" ]
                    , li [] [ text "second item" ]
                    , li [] [ text "third item" ]
                    ]
                ]
                |> Query.fromHtml
                |> Query.findAll [ tag "li" ]
                |> Query.count (Expect.equal 3)
-}
findAll : List Selector -> Single -> Multiple
findAll selectors (Internal.Single query) =
    Internal.FindAll selectors
        |> Internal.prependSelector query
        |> Internal.Multiple


{-| Find exactly one descendant element which matches all the given selectors.
If no descendants match, or if more than one matches, the test will fail.

    import Html exposing (div, ul, li)
    import Html.Attributes exposing (class)
    import Query
    import Test exposing (test)
    import Test.Html.Selector exposing (tag, classes)


    test "The list has both the classes 'items' and 'active'" <|
        \() ->
            div []
                [ ul [ class "items active" ]
                    [ li [] [ text "first item" ]
                    , li [] [ text "second item" ]
                    , li [] [ text "third item" ]
                    ]
                ]
                |> Query.fromHtml
                |> Query.find [ tag "ul" ]
                |> Query.has [ classes [ "items", "active" ] ]
-}
find : List Selector -> Single -> Single
find selectors (Internal.Single query) =
    Internal.Find selectors
        |> Internal.prependSelector query
        |> Internal.Single


{-| Return the first element in a match. If there were no matches, the test
will fail.

    import Html exposing (div, ul, li)
    import Html.Attributes exposing (class)
    import Query
    import Test exposing (test)
    import Test.Html.Selector exposing (tag, classes)


    test "The list has both the classes 'items' and 'active'" <|
        \() ->
            div []
                [ ul [ class "items active" ]
                    [ li [] [ text "first item" ]
                    , li [] [ text "second item" ]
                    , li [] [ text "third item" ]
                    ]
                ]
                |> Query.fromHtml
                |> Query.findAll [ tag "li" ]
                |> Query.first
                |> Query.has [ text "first item" ]
-}
first : Multiple -> Single
first (Internal.Multiple query) =
    Internal.First
        |> Internal.prependSelector query
        |> Internal.Single


{-| Return the element in a match at the given index. For example,
`Query.index 0` would match the first element, and `Query.index 1` would match
the second element.

If the index falls outside the bounds of the match, the test will fail.

    import Html exposing (div, ul, li)
    import Html.Attributes exposing (class)
    import Query
    import Test exposing (test)
    import Test.Html.Selector exposing (tag, classes)


    test "The list has both the classes 'items' and 'active'" <|
        \() ->
            div []
                [ ul [ class "items active" ]
                    [ li [] [ text "first item" ]
                    , li [] [ text "second item" ]
                    , li [] [ text "third item" ]
                    ]
                ]
                |> Query.fromHtml
                |> Query.findAll [ tag "li" ]
                |> Query.index 1
                |> Query.has [ text "second item" ]
-}
index : Int -> Multiple -> Single
index position (Internal.Multiple query) =
    Internal.Index position
        |> Internal.prependSelector query
        |> Internal.Single



-- EXPECTATIONS --


{-| Expect the number of elements matching the query fits the given expectation.

    import Html exposing (div, ul, li)
    import Html.Attributes exposing (class)
    import Query
    import Test exposing (test)
    import Test.Html.Selector exposing (tag)


    test "The list has three items" <|
        \() ->
            div []
                [ ul [ class "items active" ]
                    [ li [] [ text "first item" ]
                    , li [] [ text "second item" ]
                    , li [] [ text "third item" ]
                    ]
                ]
                |> Query.fromHtml
                |> Query.findAll [ tag "li" ]
                |> Query.count (Expect.equal 3)
-}
count : (Int -> Expectation) -> Multiple -> Expectation
count expect ((Internal.Multiple query) as multiple) =
    (List.length >> expect >> failWithQuery "Query.count" query)
        |> Internal.multipleToExpectation multiple


{-| Expect the element to match all of the given selectors.

    import Html exposing (div, ul, li)
    import Html.Attributes exposing (class)
    import Query
    import Test exposing (test)
    import Test.Html.Selector exposing (tag, classes)


    test "The list has both the classes 'items' and 'active'" <|
        \() ->
            div []
                [ ul [ class "items active" ]
                    [ li [] [ text "first item" ]
                    , li [] [ text "second item" ]
                    , li [] [ text "third item" ]
                    ]
                ]
                |> Query.fromHtml
                |> Query.find [ tag "ul" ]
                |> Query.has [ tag "ul", classes [ "items", "active" ] ]
-}
has : List Selector -> Single -> Expectation
has selectors (Internal.Single query) =
    Internal.has selectors query
        |> failWithQuery ("Query.has " ++ Internal.joinAsList selectorToString selectors) query


{-| Expect that a [`Single`](#Single) expectation will hold true for each of the
[`Multiple`](#Multiple) matched elements.

    import Html exposing (div, ul, li)
    import Html.Attributes exposing (class)
    import Query
    import Test exposing (test)
    import Test.Html.Selector exposing (tag, classes)


    test "The list has both the classes 'items' and 'active'" <|
        \() ->
            div []
                [ ul [ class "items active" ]
                    [ li [] [ text "first item" ]
                    , li [] [ text "second item" ]
                    , li [] [ text "third item" ]
                    ]
                ]
                |> Query.fromHtml
                |> Query.findAll [ tag "ul" ]
                |> Query.each
                    [ Query.has [ tag "ul" ]
                    , Query.has [ classes [ "items", "active" ] ]
                    ]
-}
each : (Single -> Expectation) -> Multiple -> Expectation
each check query =
    Internal.expectAll check query



-- HELPERS --


failWithQuery : String -> Internal.Query -> Expectation -> Expectation
failWithQuery queryName query expectation =
    case Expect.getFailure expectation of
        Just { given, message } ->
            (Internal.toLines message query queryName)
                |> List.map prefixOutputLine
                |> ((::) (addQueryFromHtmlLine query))
                |> String.join "\n\n\n"
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
