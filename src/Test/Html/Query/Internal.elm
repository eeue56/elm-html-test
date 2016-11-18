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
    let
        ( node, queries ) =
            prepareQuery query
    in
        queries
            |> List.foldl queryToStringHelp ( node, "" )
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
            -- TODO add details
            "descendants"

        Children criteria ->
            -- TODO add details
            "children"


prepareQuery : Query -> ( Node, List Query )
prepareQuery query =
    case prepareQueryHelp ( Nothing, [] ) query of
        ( Just node, result ) ->
            ( node, result )

        ( Nothing, _ ) ->
            Debug.crash "Unable to prepare query. Ended up with a query that was never given Html. This should never happen! Please report this as a bug."


prepareQueryHelp : ( Maybe Node, List Query ) -> Query -> ( Maybe Node, List Query )
prepareQueryHelp ( maybeNode, queries ) query =
    case query of
        Find node _ ->
            if maybeNode == Nothing then
                ( Just node, query :: queries )
            else
                Debug.crash "Unable to prepare query. Ended up with a query that was given Html *twice*. This should never happen! Please report this as a bug."

        FindAll node _ ->
            if maybeNode == Nothing then
                ( Just node, query :: queries )
            else
                Debug.crash "Unable to prepare query. Ended up with a query that was given Html *twice*. This should never happen! Please report this as a bug."

        Selector parentQuery _ ->
            prepareQueryHelp ( maybeNode, query :: queries ) parentQuery
