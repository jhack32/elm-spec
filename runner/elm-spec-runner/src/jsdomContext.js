const { JSDOM } = require("jsdom");
const { ElmContext } = require('elm-spec-core')

exports.loadElmContext = (compiler) => {
  const dom = new JSDOM(
    "<html><head><base href='http://elm-spec'></head><body></body></html>",
    { pretendToBeVisual: true,
      runScripts: "dangerously",
      url: "http://elm-spec"
    }
  )

  const context = new ElmContext(dom.window)

  const compiledCode = compiler.compile()
  
  dom.window.eval(compiledCode)

  return context
}
