module Test.Html.Query.Criteria exposing (Criteria, toString, all, classes, id, attr, class)

import Basics


type Criteria
    = All (List Criteria)
    | Classes (List String)
    | Attribute { name : String, value : String, asString : String }


toString : Criteria -> String
toString criteria =
    case criteria of
        All list ->
            list
                |> List.map toString
                |> String.join " "

        Classes list ->
            "classes " ++ Basics.toString (String.join " " list)

        Attribute { asString } ->
            asString


all : List Criteria -> Criteria
all =
    All


classes : List String -> Criteria
classes =
    Classes


id : String -> Criteria
id =
    namedAttr "id"


class : String -> Criteria
class =
    namedAttr "class"


namedAttr : String -> String -> Criteria
namedAttr name value =
    Attribute
        { name = "id"
        , value = value
        , asString = name ++ " " ++ Basics.toString value
        }


attr : String -> String -> Criteria
attr name value =
    Attribute
        { name = name
        , value = value
        , asString = "attr " ++ Basics.toString name ++ " " ++ Basics.toString value
        }
