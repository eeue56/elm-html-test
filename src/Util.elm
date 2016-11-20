module Util exposing (..)


pluralize : String -> String -> Int -> String
pluralize singular plural quantity =
    let
        prefix =
            toString quantity ++ " "
    in
        if quantity == 1 then
            prefix ++ singular
        else
            prefix ++ plural
