module Test.Html.Selector.Internal exposing (..)

import ElmHtml.InternalTypes exposing (ElmHtml)
import ElmHtml.Query


type Selector
    = All (List Selector)
    | Classes (List String)
    | Class String
    | Attribute { name : String, value : String }
    | BoolAttribute { name : String, value : Bool }
    | Style (List ( String, String ))
    | Tag String
    | Text String
    | HasChildWith (List Selector)
    | Invalid


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

        Attribute { name, value } ->
            "attribute "
                ++ toString name
                ++ " "
                ++ toString value

        BoolAttribute { name, value } ->
            "attribute "
                ++ toString name
                ++ " "
                ++ toString value

        Style style ->
            "styles " ++ styleToString style

        Tag name ->
            "tag " ++ toString name

        Text text ->
            "text " ++ toString text

        HasChildWith list ->
            list
                |> List.map selectorToString
                |> String.join " "
                |> (++) "with children "

        Invalid ->
            "invalid"


styleToString : List ( String, String ) -> String
styleToString style =
    style
        |> List.map (\( k, v ) -> k ++ ":" ++ v ++ ";")
        |> String.join " "


hasAll : List Selector -> List (ElmHtml msg) -> Bool
hasAll selectors elems =
    case selectors of
        [] ->
            True

        selector :: rest ->
            if List.isEmpty (queryAll [ selector ] elems) then
                False
            else
                hasAll rest elems


queryAll : List Selector -> List (ElmHtml msg) -> List (ElmHtml msg)
queryAll selectors list =
    case selectors of
        [] ->
            list

        selector :: rest ->
            query ElmHtml.Query.query queryAll selector list
                |> queryAll rest


queryAllChildren : List Selector -> List (ElmHtml msg) -> List (ElmHtml msg)
queryAllChildren selectors list =
    case selectors of
        [] ->
            list

        selector :: rest ->
            query ElmHtml.Query.queryChildren queryAllChildren selector list
                |> queryAllChildren rest


query :
    (ElmHtml.Query.Selector -> ElmHtml msg -> List (ElmHtml msg))
    -> (List Selector -> List (ElmHtml msg) -> List (ElmHtml msg))
    -> Selector
    -> List (ElmHtml msg)
    -> List (ElmHtml msg)
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

        Style style ->
            List.concatMap (fn (ElmHtml.Query.Style style)) list

        Tag name ->
            List.concatMap (fn (ElmHtml.Query.Tag name)) list

        Text text ->
            List.concatMap (fn (ElmHtml.Query.ContainsText text)) list

        HasChildWith selectors ->
            List.concatMap
                (\item ->
                    case query fn fnAll (All selectors) <| ElmHtml.Query.getChildren item of
                        [] ->
                            []

                        _ ->
                            [ item ]
                )
                list

        Invalid ->
            []


namedAttr : String -> String -> Selector
namedAttr name value =
    Attribute
        { name = name
        , value = value
        }


namedBoolAttr : String -> Bool -> Selector
namedBoolAttr name value =
    BoolAttribute
        { name = name
        , value = value
        }
