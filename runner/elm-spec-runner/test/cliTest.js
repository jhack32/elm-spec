const shell = require('shelljs')
const {expect} = require('chai')

describe('elm-spec-runner', () => {
  context("when the spec runs", () => {
    it("executes the spec and prints the number accepted", () => {
      const command = "./bin/run" +
        " --elm ../../node_modules/.bin/elm" +
        " --cwd ../elm-spec-core/tests/sample/" +
        " --specs ./specs/Passing/**/*Spec.elm"
      const runnerOutput = shell.exec(command, { silent: true })
      expect(runnerOutput.stdout).to.contain("Accepted: 8")
    })
  })

  context("when files are watched", () => {
    it("executes the spec once and waits for changes", async () => {
      const command = "./bin/run" +
        " --elm ../../node_modules/.bin/elm" +
        " --cwd ../elm-spec-core/tests/sample/" +
        " --specs ./specs/Passing/**/*Spec.elm" +
        " --watch"
      
      const runnerOutput = await new Promise((resolve, reject) => {
        const runner = shell.exec(command, { async: true, silent: true }, (code, stdout, stderr) => {
          resolve(stdout)
        })
  
        setTimeout(() => { runner.kill() }, 2000)  
      })

      expect(runnerOutput).to.contain("Watching Files")
      expect(runnerOutput).to.contain("../elm-spec-core/tests/sample/src/**/*.elm")
      expect(runnerOutput).to.contain("../elm-spec-core/tests/sample/specs/**/*.elm")
      expect(runnerOutput).to.contain("Accepted: 8")
    })
  })

  context("when the specified elm executable does not exist", () => {
    it("prints an error", () => {
      const command = "./bin/run --elm blah"
      const runnerOutput = shell.exec(command, { silent: true })
      expect(runnerOutput.stderr).to.contain("No elm executable found at: blah")
    })
  })

  context("when the specs elm.json cannot be found", () => {
    it("prints an error", () => {
      const command = "./bin/run" +
        " --elm ../../node_modules/.bin/elm" +
        " --cwd ../elm-spec-core/tests/"
      const runnerOutput = shell.exec(command, { silent: true })
      expect(runnerOutput.stderr).to.contain("Expected an elm.json at: ../elm-spec-core/tests/elm.json")
    })
  })

})