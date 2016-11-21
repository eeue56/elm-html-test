module Test.Html.Selector exposing (Selector, all, classes, id, attribute, boolAttribute, class, tag, text)

{-|
@docs Selector

## General Selectors

@docs tag, text, attribute, boolAttribute, all

## Attributes

@docs classes, class, id
-}

import Test.Html.Selector.Internal as Internal exposing (..)


{-| TODO
-}
type alias Selector =
    Internal.Selector


{-| TODO
-}
all : List Selector -> Selector
all =
    All


{-| TODO
-}
classes : List String -> Selector
classes =
    Classes


{-| TODO
-}
id : String -> Selector
id =
    namedAttr "id"


{-| TODO
-}
tag : String -> Selector
tag name =
    Tag
        { name = name
        , asString = "tag " ++ toString name
        }


{-| TODO
-}
class : String -> Selector
class =
    namedAttr "class"


{-| TODO
-}
attribute : String -> String -> Selector
attribute name value =
    Attribute
        { name = name
        , value = value
        , asString = "attribute " ++ toString name ++ " " ++ toString value
        }


{-| TODO
-}
boolAttribute : String -> Bool -> Selector
boolAttribute name value =
    BoolAttribute
        { name = name
        , value = value
        , asString = "boolAttribute " ++ toString name ++ " " ++ toString value
        }


{-| TODO
-}
text : String -> Selector
text =
    Internal.Text



-- HELPERS --


namedAttr : String -> String -> Selector
namedAttr name value =
    Attribute
        { name = name
        , value = value
        , asString = name ++ " " ++ toString value
        }
