const EventEmitter = require('events')
const PortPlugin = require('./plugin/portPlugin')
const TimePlugin = require('./plugin/timePlugin')
const HtmlPlugin = require('./plugin/htmlPlugin')
const HttpPlugin = require('./plugin/httpPlugin')
const { registerApp, setBaseLocation } = require('./fakes')
const { report, line } = require('./report')

module.exports = class ProgramRunner extends EventEmitter {
  static hasElmSpecPorts(app) {
    if (!app.ports.hasOwnProperty("elmSpecOut")) {
      return report(
        line("No elmSpecOut port found!"),
        line("Make sure your elm-spec program uses a port defined like so", "port elmSpecOut : Message -> Cmd msg")
      )
    }

    if (!app.ports.hasOwnProperty("elmSpecIn")) {
      return report(
        line("No elmSpecIn port found!"),
        line("Make sure your elm-spec program uses a port defined like so", "port elmSpecIn : (Message -> msg) -> Sub msg")
      )
    }

    return null
  }

  constructor(app, context, options) {
    super()
    this.app = app
    this.context = context
    this.timer = null
    this.portPlugin = new PortPlugin(app)
    this.timePlugin = new TimePlugin(this.context.clock, this.context.window)
    this.plugins = this.generatePlugins(this.context)
    this.options = options

    registerApp(this.app, this.context.window)
  }

  generatePlugins(context) {
    return {
      "_html": new HtmlPlugin(context),
      "_http": new HttpPlugin(context)
    }
  }

  run() {
    const messageHandler = (specMessage) => {
      this.handleMessage(specMessage, (outMessage) => {
        this.app.ports.elmSpecIn.send(outMessage)
      })
    }

    this.app.ports.elmSpecOut.subscribe(messageHandler)
    this.stopHandlingMessages = () => { this.app.ports.elmSpecOut.unsubscribe(messageHandler) }

    this.timePlugin.nativeSetTimeout(() => {
      this.app.ports.elmSpecIn.send(this.specStateMessage("START"))
    }, 0)
  }

  handleMessage(specMessage, out) {
    switch (specMessage.home) {
      case "_spec":
        this.handleSpecEvent(specMessage)
        break
      case "_scenario":
        this.handleScenarioEvent(specMessage, out)
        break
      case "_port":
        this.portPlugin.handle(specMessage, this.sendAbortMessage(out))
        break
      case "_time":
        this.timePlugin.handle(specMessage, () => {
          this.handleMessage(this.scenarioStateMessage("STEP_COMPLETE"), out)
        })
        break
      case "_witness":
        out(specMessage)
        break
      case "_observer":
        this.handleObserverEvent(specMessage, out)
        break
      default:
        const plugin = this.plugins[specMessage.home]
        if (plugin) {
          plugin.handle(specMessage, out, () => out(this.continue()), this.sendAbortMessage(out))
        } else {
          console.log("Message for unknown plugin:", specMessage)
        }
        break
    }
  }

  sendAbortMessage(out) {
    return (reason) => {
      out(this.abort(reason))
    }
  }

  handleObserverEvent(specMessage, out) {
    switch (specMessage.name) {
      case "inquiry":
        const inquiry = specMessage.body.message
        this.handleMessage(inquiry, (message) => {
          out({
            home: "_observer",
            name: "inquiryResult",
            body: {
              message
            }
          })
        })
        break
      case "observation": {
        const observation = specMessage.body
        this.emit('observation', observation)
        if (this.options.endOnFailure && observation.summary === "REJECT") {
          out(this.specStateMessage("FINISH"))
        } else {
          out(this.continue())
        }

        break
      }
    }
  }

  handleSpecEvent(specMessage) {
    switch (specMessage.name) {
      case "state": {
        switch (specMessage.body) {
          case "COMPLETE": {
            this.timePlugin.resetFakes()
            this.emit('complete')
            break
          }
          case "FINISHED": {
            this.timePlugin.resetFakes()
            this.emit('finished')
            break
          }
        }
        break    
      }
      case "error": {
        this.stopHandlingMessages()
        this.timePlugin.resetFakes()
        this.emit('error', specMessage.body)
        break
      }
    }
  }

  handleScenarioEvent(specMessage, out) {
    switch (specMessage.name) {
      case "state":
        this.handleStateChange(specMessage.body, out)
        break
    }
  }

  handleStateChange(state, out) {
    switch (state) {
      case "START":
        this.prepareForScenario(out)
        out(this.continue())
        break
      case "CONFIGURE_COMPLETE":
        out(this.continue())
        break
      case "STEP_COMPLETE":
        if (this.timer) clearTimeout(this.timer)
        this.timer = this.timePlugin.nativeSetTimeout(() => {
          out(this.continue())
        }, 0)
        this.startTimeoutTimer(out)
        break
      case "OBSERVATION_START":
        this.scenarioExerciseComplete()
        out(this.continue())
        break
      case "ABORT":
        this.scenarioExerciseComplete()
        break
    }
  }

  abort(reason) {
    return {
      home: "_scenario",
      name: "abort",
      body: reason
    }
  }

  scenarioExerciseComplete() {
    this.stopTimeoutTimer()
    this.portPlugin.unsubscribe()
  }

  prepareForScenario(out) {
    this.timePlugin.clearTimers()
    setBaseLocation("http://elm-spec", this.context.window)
    this.startTimeoutTimer(out)
  }

  startTimeoutTimer(out) {
    this.stopTimeoutTimer()
    this.scenarioTimeout = this.timePlugin.nativeSetTimeout(() => {
      out(this.abort(report(line(`Scenario timeout of ${this.options.timeout}ms exceeded!`))))
    }, this.options.timeout)
  }

  stopTimeoutTimer() {
    if (this.scenarioTimeout) clearTimeout(this.scenarioTimeout)
  }

  continue () {
    return this.scenarioStateMessage("CONTINUE")
  }

  specStateMessage (state) {
    return {
      home: "_spec",
      name: "state",
      body: state
    }
  }

  scenarioStateMessage (state) {
    return {
      home: "_scenario",
      name: "state",
      body: state
    }
  }
}