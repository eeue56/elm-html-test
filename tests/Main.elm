port module Main exposing (..)

import Test.Runner.Node exposing (run, TestProgram)
import Test exposing (..)
import Json.Encode exposing (Value)
import TestExample
import Queries


main : TestProgram
main =
    [ TestExample.all
    , Queries.all
    ]
        |> Test.concat
        |> run emit


port emit : ( String, Value ) -> Cmd msg
