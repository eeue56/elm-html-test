# elm-html-test

Test views by writing expectations about `Html` values.

```
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

1. Call `Query.fromHtml` on your `Html` to begin querying it.
2. Use queries like `Query.find` and `Query.findAll` to find the elements to test.
3. Create expectations using things like `Query.has` and `Query.count`.

These are normal expectations, so you can use them with [`fuzz`](http://package.elm-lang.org/packages/elm-community/elm-test/latest/Test#fuzz) just as easily as with [`test`](http://package.elm-lang.org/packages/elm-community/elm-test/3.1.0/Test#test)!

## Releases
| Version | Notes |
| ------- | ----- |
| [**1.0.0**](https://github.com/eeue56/elm-html-test/tree/1.0.0) | Initial release
