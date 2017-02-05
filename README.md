# elm-html-test

Test views by writing expectations about `Html` values. [![Build Status](https://travis-ci.org/eeue56/elm-html-test.svg?branch=master)](https://travis-ci.org/eeue56/elm-html-test)

```elm
import Html
import Html.Attributes exposing (class)
import Test exposing (test)
import Test.Html.Query as Query
import Test.Html.Selector exposing (text, tag)


test "Button has the expected text" <|
    \() ->
        Html.div [ class "container" ]
            [ Html.button [] [ Html.text "I'm a button!" ] ]
            |> Query.fromHtml
            |> Query.find [ tag "button" ]
            |> Query.has [ text "I'm a button!" ]
```

These tests are designed to be written in a pipeline like this:

1. Call [`Query.fromHtml`](http://package.elm-lang.org/packages/eeue56/elm-html-test/latest/Test-Html-Query#fromHtml) on your [`Html`](http://package.elm-lang.org/packages/elm-lang/html/latest/Html#Html) to begin querying it.
2. Use queries like [`Query.find`](http://package.elm-lang.org/packages/eeue56/elm-html-test/latest/Test-Html-Query#find), [`Query.findAll`](http://package.elm-lang.org/packages/eeue56/elm-html-test/latest/Test-Html-Query#findAll), and [`Query.children`](http://package.elm-lang.org/packages/eeue56/elm-html-test/latest/Test-Html-Query#children) to find the elements to test.
3. Create expectations using things like [`Query.has`](http://package.elm-lang.org/packages/eeue56/elm-html-test/latest/Test-Html-Query#has) and [`Query.count`](http://package.elm-lang.org/packages/eeue56/elm-html-test/latest/Test-Html-Query#count).

These are normal expectations, so you can use them with [`fuzz`](http://package.elm-lang.org/packages/elm-community/elm-test/latest/Test#fuzz) just as easily as with [`test`](http://package.elm-lang.org/packages/elm-community/elm-test/3.1.0/Test#test)!

## Querying

Queries come in two flavors: [`Single`](http://package.elm-lang.org/packages/eeue56/elm-html-test/latest/Test-Html-Query#Single) and [`Multiple`](http://package.elm-lang.org/packages/eeue56/elm-html-test/latest/Test-Html-Query#Multiple).

This is because some queries are expected to return a single result, whereas
others may return multiple results.

If a `Single` query finds exactly one result, it will succeed and continue with
any further querying or expectations. If it finds zero results, or more than one,
the test will fail.

Since other querying and expectation functions are written in terms of `Single`
and `Multiple`, the compiler can help make sure queries are connected as
expected. For example, [`count`](http://package.elm-lang.org/packages/eeue56/elm-html-test/latest/Test-Html-Query#count) accepts a `Multiple`, because counting a single element does not make much sense!

If you have a `Multiple` and want to use an expectation that works on a `Single`,
such as [`Query.has`](http://package.elm-lang.org/packages/eeue56/elm-html-test/latest/Test-Html-Query#has), you can use [`Query.each`](http://package.elm-lang.org/packages/eeue56/elm-html-test/latest/Test-Html-Query#each) to run the expectation on each of the elements in the `Multiple`.

## Releases
| Version | Notes |
| ------- | ----- |
| [**1.0.0**](https://github.com/eeue56/elm-html-test/tree/1.0.0) | Initial release
