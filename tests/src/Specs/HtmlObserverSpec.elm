module Specs.HtmlObserverSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Html as Markup
import Spec.Html.Selector exposing (..)
import Html exposing (Html)
import Html.Attributes as Attr
import Runner


hasTextSpec : Spec Model Msg
hasTextSpec =
  Spec.describe "hasText"
  [ scenario "the hasText matcher is satisfied" (
      Subject.initWithModel { activity = "running" }
        |> Subject.withView testTextView
    )
    |> it "matches the text" (
      Markup.select << by [ id "my-activity" ]
        |> Markup.expectElement (Markup.hasText "My activity is: running!")
    )
  , scenario "the hasText matcher fails" (
      Subject.initWithModel { activity = "Running" }
       |> Subject.withView testTextView
    )
    |> it "renders the name based on the model" (
      Markup.select << by [ id "my-activity" ]
        |> Markup.expectElement (Markup.hasText "Something not present")
    )
  ]


hasTextContainedSpec : Spec Model Msg
hasTextContainedSpec =
  Spec.describe "hasText"
  [ scenario "the hasText matcher is satisfied" (
      Subject.initWithModel { activity = "swimming" }
        |> Subject.withView testTextView
    )
    |> it "matches the text" (
      Markup.select << by [ id "things" ]
        |> Markup.expectElement (Markup.hasText "swimming")
    )
  ]


testTextView : Model -> Html Msg
testTextView model =
  Html.div []
  [ Html.div [ Attr.id "my-activity" ] [ Html.text <| "My activity is: " ++ model.activity ++ "!" ]
  , Html.ol [ Attr.id "things" ]
    [ Html.li [] [ Html.text "bowling" ]
    , Html.li [] [ Html.text model.activity ]
    , Html.li [] [ Html.text "walking" ]
    ]
  ]


hasAttributeSpec : Spec Model Msg
hasAttributeSpec =
  Spec.describe "hasAttribute"
  [ scenario "when the element has the attribute with the right value" (
      Subject.initWithModel { activity = "bowling" }
        |> Subject.withView testAttributeView
    )
    |> it "sets the attribute value based on the model" (
      Markup.select << by [ id "activity" ]
        |> Markup.expectElement (Markup.hasAttribute ("data-fun-activity", "bowling"))
    )
  , scenario "when the element does not have the expected attribute" (
      Subject.initWithModel { activity = "bowling" }
        |> Subject.withView testAttributeView
    )
    |> it "sets the attribute value based on the model" (
      Markup.select << by [ id "activity" ]
        |> Markup.expectElement (Markup.hasAttribute ("data-unknown-attribute", "bowling"))
    )
  , scenario "when the element has the attribute with the wrong value" (
      Subject.initWithModel { activity = "bowling" }
        |> Subject.withView testAttributeView
    )
    |> it "sets the attribute value based on the model" (
      Markup.select << by [ id "activity" ]
        |> Markup.expectElement (Markup.hasAttribute ("data-fun-activity", "running"))
    )
  , scenario "when the element has no attributes" (
      Subject.initWithModel { activity = "bowling" }
        |> Subject.withView testAttributeView
    )
    |> it "sets the attribute value based on the model" (
      Markup.select << by [ tag "h1" ]
        |> Markup.expectElement (Markup.hasAttribute ("data-fun-activity", "running"))
    )
  ]


type alias Model =
  { activity: String
  }


type Msg
  = Msg


testAttributeView : Model -> Html Msg
testAttributeView model =
  Html.div []
  [ Html.div [ Attr.id "activity", Attr.attribute "data-fun-activity" model.activity ]
    [ Html.text "Fun!" ]
  , Html.h1 [] [ Html.text "something" ]
  ]


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "hasText" -> Just hasTextSpec
    "hasTextContained" -> Just hasTextContainedSpec
    "hasAttribute" -> Just hasAttributeSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec