module Specs.ExpectModelSpec exposing (..)

import Spec exposing (Spec(..))
import Spec.Subject as Subject
import Observer
import Runner


failingSpec : Spec Model Msg
failingSpec =
  Spec.given
    << Subject.fragment testUpdate
    << Subject.withModel (\_ -> { count = 99 })
  |> Spec.when
    << Spec.nothing
  |> Spec.it "fails" (
    Spec.expectModel <|
      \model ->
        Observer.isEqual 17 model.count
  )


passingSpec : Spec Model Msg
passingSpec =
  Spec.given
    << Subject.fragment testUpdate
    << Subject.withModel (\_ -> { count = 99 })
  |> Spec.when
    << Spec.nothing
  |> Spec.it "contains the expected value" (
      Spec.expectModel <|
        \model ->
          Observer.isEqual 99 model.count
  )


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  ( model, Cmd.none )


selectSpec : String -> Spec Model Msg
selectSpec specName =
  case specName of
    "failing" ->
      failingSpec
    "passing" ->
      passingSpec
    _ ->
      failingSpec


type Msg
  = Msg


type alias Model =
  { count: Int
  }


main =
  Runner.program selectSpec