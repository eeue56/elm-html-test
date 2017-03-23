module Test.Html.Selector.Internal exposing (..)

import Dict
import ElmHtml.InternalTypes exposing (..)
import ElmHtml.Query exposing (Selector(..))


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


getChildren : ElmHtml -> List ElmHtml
getChildren node =
    case node of
        NodeEntry { children } ->
            children

        _ ->
            []


queryOnlyChildren : List Selector -> List ElmHtml -> List ElmHtml
queryOnlyChildren selectors list =
    applySelectors selectors (List.concatMap getChildren list)


applySelectors : List Selector -> List ElmHtml -> List ElmHtml
applySelectors selectors elements =
    case selectors of
        [] ->
            elements

        selector :: rest ->
            List.filter (trySelector selector) elements
                |> applySelectors rest


trySelector : Selector -> ElmHtml -> Bool
trySelector selector node =
    predicateFromSelector (toQuerySelector selector) node


predicateFromSelector : ElmHtml.Query.Selector -> ElmHtml -> Bool
predicateFromSelector selector html =
    case html of
        NodeEntry record ->
            record
                |> nodeRecordPredicate selector

        _ ->
            False


hasAttribute : String -> String -> Facts -> Bool
hasAttribute attribute query facts =
    case Dict.get attribute facts.stringAttributes of
        Just id ->
            id == query

        Nothing ->
            False


hasBoolAttribute : String -> Bool -> Facts -> Bool
hasBoolAttribute attribute value facts =
    case Dict.get attribute facts.boolAttributes of
        Just id ->
            id == value

        Nothing ->
            False


classnames : Facts -> List String
classnames facts =
    Dict.get "className" facts.stringAttributes
        |> Maybe.withDefault ""
        |> String.split " "


hasClass : String -> Facts -> Bool
hasClass query facts =
    List.member query (classnames facts)


hasClasses : List String -> Facts -> Bool
hasClasses classList facts =
    containsAll classList (classnames facts)


containsAll : List a -> List a -> Bool
containsAll a b =
    b
        |> List.foldl (\i acc -> List.filter ((/=) i) acc) a
        |> List.isEmpty


hasAllSelectors : List ElmHtml.Query.Selector -> ElmHtml -> Bool
hasAllSelectors selectors record =
    List.map predicateFromSelector selectors
        |> List.map (\selector -> selector record)
        |> List.all identity


nodeRecordPredicate : ElmHtml.Query.Selector -> (NodeRecord -> Bool)
nodeRecordPredicate selector =
    case selector of
        Id id ->
            .facts
                >> hasAttribute "id" id

        ClassName classname ->
            .facts
                >> hasClass classname

        ClassList classList ->
            .facts
                >> hasClasses classList

        ElmHtml.Query.Tag tag ->
            .tag
                >> (==) tag

        ElmHtml.Query.Attribute key value ->
            .facts
                >> hasAttribute key value

        ElmHtml.Query.BoolAttribute key value ->
            .facts
                >> hasBoolAttribute key value

        ContainsText text ->
            always False

        Multiple selectors ->
            NodeEntry
                >> hasAllSelectors selectors



-- queryOnlyChildren : List Selector -> List ElmHtml -> List ElmHtml
-- queryOnlyChildren selectors list =
--     let
--         querySelectors =
--             List.map toQuerySelector selectors
--
--         parentNode =
--             List.head list
--
--         dropParentIfIncluded elements =
--             if List.head elements == parentNode then
--                 List.drop 1 elements
--             else
--                 elements
--     in
--         List.concatMap (ElmHtml.Query.queryChildrenAll querySelectors) list
--             |> dropParentIfIncluded


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
