const { expectBrowserSpec, expectAccepted, expectRejected, reportLine } = require("./helpers/SpecHelpers")

describe("Navigation", () => {
  context("when a new url is loaded", () => {
    it("performs the spec as expected", (done) => {
      expectBrowserSpec("NavigationSpec", "loadUrl", done, (observations) => {
        expectAccepted(observations[0])
      })
    })
  })

  context("when the page is reloaded", () => {
    it("performs the spec as expected", (done) => {
      expectBrowserSpec("NavigationSpec", "reload", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectRejected(observations[2], [
          reportLine("Expected Browser.Navigation.reload or Browser.Navigation.reloadAndSkipCache but neither command was executed")
        ])
      })
    })
  })
})