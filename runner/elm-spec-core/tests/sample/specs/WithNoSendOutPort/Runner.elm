port module WithNoSendOutPort.Runner exposing (..)

import Spec exposing (Spec)
import Spec.Message exposing (Message)


port somerthingOtherThanSendOut : Message -> Cmd msg
port elmSpecIn : (Message -> msg) -> Sub msg


config : Spec.Config msg
config =
  { send = somerthingOtherThanSendOut
  , outlet = somerthingOtherThanSendOut
  , listen = elmSpecIn
  }


program specs =
  Spec.browserProgram config specs


workerProgram specs =
  Spec.program config specs