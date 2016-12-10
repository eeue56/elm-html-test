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
                |> queryAllChildren rest


queryAllChildren : List Selector -> List ElmHtml -> List ElmHtml
queryAllChildren selectors list =
    case selectors of
        [] ->
            list

        selector :: rest ->
            query ElmHtml.Query.queryChildren queryAllChildren selector list
                |> queryAllChildren rest


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
