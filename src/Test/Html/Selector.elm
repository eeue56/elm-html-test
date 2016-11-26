module Test.Html.Selector
    exposing
        ( Selector
        , all
        , id
        , attribute
        , boolAttribute
        , class
        , classes
        , className
        , index
        , tag
        , text
        , checked
        , selected
        , disabled
        )

{-|
@docs Selector

## General Selectors

@docs tag, text, attribute, boolAttribute, index, all

## Attributes

@docs id, class, classes, className, checked, selected, disabled
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
class : String -> Selector
class name =
    classes [ name ]


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
className : String -> Selector
className =
    namedAttr "className"


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


{-| TODO
-}
selected : Bool -> Selector
selected =
    namedBoolAttr "selected"


{-| TODO
-}
disabled : Bool -> Selector
disabled =
    namedBoolAttr "disabled"


{-| TODO
-}
checked : Bool -> Selector
checked =
    namedBoolAttr "checked"


{-| TODO
-}
index : Int -> Selector
index =
    Debug.crash "TODO"



-- HELPERS --


namedAttr : String -> String -> Selector
namedAttr name value =
    Attribute
        { name = name
        , value = value
        , asString = name ++ " " ++ toString value
        }


namedBoolAttr : String -> Bool -> Selector
namedBoolAttr name value =
    BoolAttribute
        { name = name
        , value = value
        , asString = name ++ " " ++ toString value
        }
