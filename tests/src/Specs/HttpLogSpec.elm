module Specs.HttpLogSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Claim exposing (..)
import Spec.Http
import Spec.Http.Route exposing (..)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Http
import Runner


httpRequestLogSpec : Spec Model Msg
httpRequestLogSpec =
  Spec.describe "logRequests"
  [ scenario "there are requests" (
      given (
        testSubject
          [ getRequest "http://fun.com/fun/1"
          , getRequest "http://awesome.com/awesome?name=cool"
          , postRequest "http://super.com/super"
          ]
      )
      |> when "requests are sent"
        [ Markup.target << by [ id "request-button" ]
        , Event.click
        , Spec.Http.log
        , Event.click
        , Spec.Http.log
        , Event.click
        , Spec.Http.log
        ]
      |> observeThat
        [ it "makes the GET requests" (
            Spec.Http.observeRequests (route "GET" <| Matching ".+")
              |> expect (isListWithLength 2)
          )
        , it "makes the POST requests" (
            Spec.Http.observeRequests (route "POST" <| Matching ".+")
              |> expect (isListWithLength 1)
          )
        ]
    )
  , scenario "there are no requests" (
      given (
        testSubject []
      )
      |> when "the requests are logged"
        [ Spec.Http.log
        ]
      |> it "makes no GET requests" (
        Spec.Http.observeRequests (route "GET" <| Matching ".+")
          |> expect (isListWithLength 0)
      )
    )
  ]


getRequest url =
  Http.get
    { url = url
    , expect = Http.expectString ReceivedRequest
    }


postRequest url =
  Http.post
    { url = url
    , body = Http.emptyBody
    , expect = Http.expectString ReceivedRequest
    }


testSubject requests =
  Setup.initWithModel (defaultModel requests)
    |> Setup.withView testView
    |> Setup.withUpdate testUpdate


type alias Model =
  { requests : List (Cmd Msg)
  }


defaultModel requests =
  { requests = requests
  }


type Msg
  = SendRequest
  | ReceivedRequest (Result Http.Error String)


testUpdate : Msg -> Model -> (Model, Cmd Msg)
testUpdate msg model =
  case msg of
    SendRequest ->
      case model.requests of
        [] ->
          ( model, Cmd.none )
        next :: requests ->
          ( { model | requests = requests }
          , next
          )
    ReceivedRequest _ ->
      ( model, Cmd.none )


testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.button [ Attr.id "request-button", Events.onClick SendRequest ] [ Html.text "Send Next Request!" ]
  ]


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "logRequests" -> Just httpRequestLogSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec