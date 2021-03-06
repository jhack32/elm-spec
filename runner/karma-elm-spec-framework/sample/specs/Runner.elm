port module Runner exposing (..)

import Spec exposing (Message)

port elmSpecOut : Message -> Cmd msg
port elmSpecIn : (Message -> msg) -> Sub msg


config : Spec.Config msg
config =
  { send = elmSpecOut
  , listen = elmSpecIn
  }


skip =
  Spec.skip


program =
  Spec.browserProgram config
