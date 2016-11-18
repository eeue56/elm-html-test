module Test.Html.Query.Internal exposing (..)

import Test.Html.Query.Criteria as Criteria exposing (Criteria)
import Html.Inert as Inert exposing (Node)


type Query
    = Query Inert.Node (List Selector) Starter


type Starter
    = Find (List Criteria)
    | FindAll (List Criteria)


type Selector
    = Descendants (List Criteria)
    | Children (List Criteria)


type Single
    = Single Query


type Multiple
    = Multiple Query


toLines : Query -> List String
toLines (Query node selectors starter) =
    let
        starterStr =
            case starter of
                Find criteria ->
                    "Query.find " ++ joinAsList Criteria.toString criteria

                FindAll criteria ->
                    "Query.findAll " ++ joinAsList Criteria.toString criteria

        selectorStr =
            List.map (selectorToString node) selectors
    in
        starterStr :: selectorStr


selectorToString : Node -> Selector -> String
selectorToString node selector =
    case selector of
        Descendants criteria ->
            "Query.descendants " ++ joinAsList Criteria.toString criteria

        Children criteria ->
            "Query.children " ++ joinAsList Criteria.toString criteria


joinAsList : (a -> String) -> List a -> String
joinAsList toStr list =
    if List.isEmpty list then
        "[]"
    else
        "[ " ++ String.join ", " (List.map toStr list) ++ " ]"


prependSelector : Query -> Selector -> Query
prependSelector (Query node selectors starter) selector =
    Query node (selector :: selectors) starter
