module Test.Html.Selector exposing (Selector, all, classes, id, attr, class, tag, text)

{-|
@docs Selector

## General Selectors

@docs attr, tag, text, all

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
attr : String -> String -> Selector
attr name value =
    Attribute
        { name = name
        , value = value
        , asString = "attr " ++ toString name ++ " " ++ toString value
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
        { name = "id"
        , value = value
        , asString = name ++ " " ++ toString value
        }
