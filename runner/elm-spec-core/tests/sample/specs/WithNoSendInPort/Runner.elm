port module WithNoSendInPort.Runner exposing (..)

import Spec exposing (Spec)
import Spec.Message exposing (Message)


port sendOut : Message -> Cmd msg
port somethingOtherThanSendIn : (Message -> msg) -> Sub msg


config : Spec.Config msg
config =
  { send = sendOut
  , outlet = sendOut
  , listen = somethingOtherThanSendIn
  }


program specs =
  Spec.browserProgram config specs


workerProgram specs =
  Spec.program config specs