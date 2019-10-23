module Specs.NavigationSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Markup as Markup
import Spec.Markup.Navigation as Navigation
import Spec.Observer as Observer
import Spec.Claim exposing (..)
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Browser.Navigation
import Runner
import Url
import Task


loadUrlSpec : Spec Model Msg
loadUrlSpec =
  Spec.describe "a program that uses Browser.Navigation.loadUrl"
  [ scenario "a new URL is loaded" (
      given (
        Subject.initWithModel ()
          |> Subject.withView testView
          |> Subject.withUpdate testUpdate
          |> Subject.withLocation testUrl
      )
      |> when "a new page load is triggered"
        [ target << by [ id "load-button" ]
        , Event.click
        ]
      |> it "updates the document location" (
        Navigation.observeLocation
          |> expect (isEqual "http://navigation-test-app.com/some-fun-place")
      )
    )
  , scenario "checking the default location" (
      given (
        Subject.initWithModel ()
          |> Subject.withView testView
          |> Subject.withUpdate testUpdate
          |> Subject.withLocation testUrl
      )
      |> it "shows the default location" (
        Navigation.observeLocation
          |> expect (isEqual "http://navigation-test-app.com/")
      )
    )
  ]


testUrl =
  { protocol = Url.Http
  , host = "navigation-test-app.com"
  , port_ = Nothing
  , path = "/"
  , query = Nothing
  , fragment = Nothing
  }


reloadSpec : Spec Model Msg
reloadSpec =
  Spec.describe "a program that reloads the page"
  [ scenario "Browser.Navigation.reload is used" (
      given (
        Subject.initWithModel ()
          |> Subject.withView testView
          |> Subject.withUpdate testUpdate
      )
      |> when "a reload is triggered"
        [ target << by [ id "reload-button" ]
        , Event.click
        ]
      |> it "records the reload" (
        Navigation.expectReload
      )
    )
  , scenario "Browser.Navigation.reloadAndSkipCache is used" (
      given (
        Subject.initWithModel ()
          |> Subject.withView testView
          |> Subject.withUpdate testUpdate
      )
      |> when "a reload is triggered"
        [ target << by [ id "reload-skip-cache-button" ]
        , Event.click
        ]
      |> it "records the reload" (
        Navigation.expectReload
      )
    )
  , scenario "the page has not been reloaded" (
      given (
        Subject.initWithModel ()
          |> Subject.withView testView
          |> Subject.withUpdate testUpdate
      )
      |> it "records the reload" (
        Navigation.expectReload
      )
    )
  ]


batchLoadSpec : Spec Model Msg
batchLoadSpec =
  Spec.describe "batching load with another command"
  [ scenario "load and something else" (
      given (
        Subject.initWithModel ()
          |> Subject.withView testView
          |> Subject.withUpdate testUpdate
          |> Subject.withLocation testUrl
      )
      |> when "the batch command is triggered"
        [ target << by [ id "load-and-send" ]
        , Event.click
        ]
      |> it "changes the location" (
        Navigation.observeLocation
          |> expect (isEqual "http://navigation-test-app.com/some-awesome-place")
      )
    )
  ]

type alias Model =
  ()

type Msg
  = ChangeLocation
  | Reload
  | ReloadSkipCache
  | LoadAndSend
  | Ignore

testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.button [ Attr.id "load-button", Events.onClick ChangeLocation ]
    [ Html.text "Click to change location!" ]
  , Html.button [ Attr.id "reload-button", Events.onClick Reload ]
    [ Html.text "Click to reload!" ]
  , Html.button [ Attr.id "reload-skip-cache-button", Events.onClick ReloadSkipCache ]
    [ Html.text "Click to reload and skip cache!" ]
  , Html.button [ Attr.id "load-and-send", Events.onClick LoadAndSend ]
    [ Html.text "Click to load and send!" ]
  ]

testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    ChangeLocation ->
      ( model
      , Browser.Navigation.load "/some-fun-place"
      )
    Reload ->
      ( model
      , Browser.Navigation.reload
      )
    ReloadSkipCache ->
      ( model
      , Browser.Navigation.reloadAndSkipCache
      )
    LoadAndSend ->
      ( model
      , Cmd.batch
        [ Task.succeed never |> Task.perform (always Ignore)
        , Browser.Navigation.load "/some-awesome-place"
        ]
      )
    Ignore ->
      ( model, Cmd.none )


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "loadUrl" -> Just loadUrlSpec
    "reload" -> Just reloadSpec
    "batchLoad" -> Just batchLoadSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec