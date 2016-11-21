module Test.Html.Query.Selector exposing (Selector, all, classes, id, attr, class, tag, text)

import Test.Html.Query.Selector.Internal as Internal exposing (..)


type alias Selector =
    Internal.Selector


all : List Selector -> Selector
all =
    All


classes : List String -> Selector
classes =
    Classes


id : String -> Selector
id =
    namedAttr "id"


tag : String -> Selector
tag name =
    Tag
        { name = name
        , asString = "tag " ++ toString name
        }


class : String -> Selector
class =
    namedAttr "class"


attr : String -> String -> Selector
attr name value =
    Attribute
        { name = name
        , value = value
        , asString = "attr " ++ toString name ++ " " ++ toString value
        }


text : String -> Selector
text =
    Internal.Text



-- HELPERS --


namedAttr : String -> String -> Selector
namedAttr name value =
    Attribute
        { name = "id"
        , value = value
        , asString = name ++ " " ++ toString value
        }
