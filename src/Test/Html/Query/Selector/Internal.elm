module Test.Html.Query.Selector.Internal exposing (..)

import ElmHtml.InternalTypes exposing (ElmHtml)
import ElmHtml.Query


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


queryAll : List Selector -> List ElmHtml -> List ElmHtml
queryAll selectors list =
    case selectors of
        [] ->
            list

        selector :: rest ->
            queryAll rest (query selector list)


query : Selector -> List ElmHtml -> List ElmHtml
query selector list =
    case selector of
        All selectors ->
            queryAll selectors list

        Classes classes ->
            List.concatMap (ElmHtml.Query.queryByClassList classes) list

        Attribute { name, value } ->
            List.concatMap (ElmHtml.Query.queryByAttribute name value) list

        Tag { name } ->
            List.concatMap (ElmHtml.Query.queryByTagName name) list
