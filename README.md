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

1. Run your view logic to get a `Html` value.
2. Call `Query.fromHtml` on it to begin querying it.
3. Use queries like `Query.find` and `Query.findAll`
