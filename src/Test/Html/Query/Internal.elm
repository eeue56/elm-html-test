module Test.Html.Query.Internal exposing (..)

import Test.Html.Query.Criteria as Criteria exposing (Criteria)
import Html.Inert as Inert exposing (Node)


type Query
    = Find Inert.Node (List Criteria)
    | FindAll Inert.Node (List Criteria)
    | Selector Query Selector


type Selector
    = Descendants (List Criteria)
    | Children (List Criteria)


type Single
    = Single Query


type Multiple
    = Multiple Query


queryToString : Query -> String
queryToString query =
    query
        |> queryToList
        |> List.foldl queryToStringHelp ( Inert.empty, "" )
        |> Tuple.second


queryToStringHelp : Query -> ( Node, String ) -> ( Node, String )
queryToStringHelp query ( node, result ) =
    let
        ( newNode, newStr ) =
            case query of
                Find rootNode criteria ->
                    ( rootNode, "find [ " ++ String.join ", " (List.map Criteria.toString criteria) ++ " ]" )

                FindAll rootNode criteria ->
                    ( rootNode, "findAll [ " ++ String.join " " (List.map Criteria.toString criteria) ++ " ]" )

                Selector _ selector ->
                    ( node, selectorToString node selector )
    in
        ( newNode, result ++ "\n\n" ++ newStr )


selectorToString : Node -> Selector -> String
selectorToString node selector =
    case selector of
        Descendants criteria ->
            "descendants"

        Children criteria ->
            -- TODO add details
            "children"


singleToList : Single -> List Query
singleToList (Single query) =
    queryToList query


multipleToList : Multiple -> List Query
multipleToList (Multiple query) =
    queryToList query


queryToList : Query -> List Query
queryToList =
    queryToListHelp []


queryToListHelp : List Query -> Query -> List Query
queryToListHelp result current =
    case current of
        Find _ _ ->
            current :: result

        FindAll _ _ ->
            current :: result

        Selector query _ ->
            queryToListHelp (current :: result) query
