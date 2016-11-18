module Test.Html.Query.Selector.Internal exposing (..)


type Selector
    = All (List Selector)
    | Classes (List String)
    | Attribute { name : String, value : String, asString : String }
    | Tag { name : String, asString : String }


selectorToString : Selector -> String
selectorToString criteria =
    case criteria of
        All list ->
            list
                |> List.map selectorToString
                |> String.join " "

        Classes list ->
            "classes " ++ toString (String.join " " list)

        Attribute { asString } ->
            asString

        Tag { asString } ->
            asString
