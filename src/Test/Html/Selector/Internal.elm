module Test.Html.Selector.Internal exposing (..)

import ElmHtml.InternalTypes exposing (ElmHtml)
import ElmHtml.Query


type Selector
    = All (List Selector)
    | Classes (List String)
    | Class String
    | Attribute { name : String, value : String, asString : String }
    | BoolAttribute { name : String, value : Bool, asString : String }
    | Tag { name : String, asString : String }
    | Text String


selectorToString : Selector -> String
selectorToString criteria =
    case criteria of
        All list ->
            list
                |> List.map selectorToString
                |> String.join " "

        Classes list ->
            "classes " ++ toString (String.join " " list)

        Class class ->
            "class " ++ toString class

        Attribute { asString } ->
            asString

        BoolAttribute { asString } ->
            asString

        Tag { asString } ->
            asString

        Text text ->
            "text " ++ toString text


queryAll : List Selector -> List ElmHtml -> List ElmHtml
queryAll selectors list =
    case selectors of
        [] ->
            list

        selector :: rest ->
            query ElmHtml.Query.query queryAll selector list
                |> queryAll rest


queryOnlyChildren : List Selector -> List ElmHtml -> List ElmHtml
queryOnlyChildren selectors list =
    let
        querySelectors =
            List.map toQuerySelector selectors

        parentNode =
            List.head list

        dropParentIfIncluded elements =
            if List.head elements == parentNode then
                List.drop 1 elements
            else
                elements
    in
        List.concatMap (ElmHtml.Query.queryChildrenAll querySelectors) list
            |> dropParentIfIncluded


toQuerySelector : Selector -> ElmHtml.Query.Selector
toQuerySelector selector =
    case selector of
        All selectors ->
            ElmHtml.Query.Multiple (List.map toQuerySelector selectors)

        Classes classes ->
            ElmHtml.Query.ClassList classes

        Class class ->
            ElmHtml.Query.ClassList [ class ]

        Attribute { name, value } ->
            ElmHtml.Query.Attribute name value

        BoolAttribute { name, value } ->
            ElmHtml.Query.BoolAttribute name value

        Tag { name } ->
            ElmHtml.Query.Tag name

        Text text ->
            ElmHtml.Query.ContainsText text


query :
    (ElmHtml.Query.Selector -> ElmHtml -> List ElmHtml)
    -> (List Selector -> List ElmHtml -> List ElmHtml)
    -> Selector
    -> List ElmHtml
    -> List ElmHtml
query fn fnAll selector list =
    case selector of
        All selectors ->
            fnAll selectors list

        Classes classes ->
            List.concatMap (fn (ElmHtml.Query.ClassList classes)) list

        Class class ->
            List.concatMap (fn (ElmHtml.Query.ClassList [ class ])) list

        Attribute { name, value } ->
            List.concatMap (fn (ElmHtml.Query.Attribute name value)) list

        BoolAttribute { name, value } ->
            List.concatMap (fn (ElmHtml.Query.BoolAttribute name value)) list

        Tag { name } ->
            List.concatMap (fn (ElmHtml.Query.Tag name)) list

        Text text ->
            List.concatMap (fn (ElmHtml.Query.ContainsText text)) list
