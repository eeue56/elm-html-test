module Expect.Html exposing (..)

import Test.Html.Query.Criteria as Criteria exposing (Criteria)
import Test.Html.Query as Query exposing (Single, Multiple)
import Test.Html.Query.Internal as Internal
import Expect exposing (Expectation)


all : (Single -> Expectation) -> Multiple -> Expectation
all =
    Debug.crash "TODO"


has : Criteria -> Single -> Expectation
has =
    Debug.crash "TODO"


count : Multiple -> (Int -> Expectation) -> Expectation
count =
    Debug.crash "TODO"
