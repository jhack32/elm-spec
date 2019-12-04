module TestSpec exposing (main)

import Spec exposing (..)
import Spec.Subject as Subject
import Spec.Claim as Claim exposing (Claim)
import Spec.Observer as Observer
import RunnerWithBadSendOut


testSpec : Spec () Msg
testSpec =
  Spec.describe "test"
  [ scenario "passing" (
      given (
        Subject.initWithModel ()
      )
      |> it "passes" (
        Observer.observeModel identity
          |> expect (equals ())
      )
    )
  ]


type Msg
  = Msg


equals : a -> Claim a
equals =
  Claim.isEqual Debug.toString


main =
  RunnerWithBadSendOut.program
    [ testSpec
    ]