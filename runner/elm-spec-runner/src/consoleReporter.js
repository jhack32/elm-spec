const chalk = require('chalk')
const readline = require('readline')

const ok = chalk.green
const error = chalk.red
const skip = chalk.yellow
const logMessage = chalk.cyan

module.exports = class ConsoleReporter {
  constructor({ write, writeLine, stream }) {
    this.write = write
    this.writeLine = writeLine
    this.stream = stream
    this.reset()
  }

  reset() {
    this.accepted = 0
    this.skipped = 0
    this.rejected = []
    this.hasError = false
  }

  async performAction(startMessage, doneMessage, action) {
    this.printLine(startMessage)
    this.printLine()
    const didAction = await action()
    if (didAction) {
      readline.cursorTo(this.stream, 0)
      readline.moveCursor(this.stream, 0, -2)
      this.printLine(`${startMessage}${doneMessage}`)
    }
  }

  print(message = "") {
    this.write(message)
  }

  printLine(message = "") {
    this.writeLine(message)
  }

  startSuite() {
    this.write("\nRunning specs: ")
  }

  record(observation) {
    switch (observation.summary) {
      case "ACCEPTED":
        this.accepted += 1
        this.write(ok('.'))
        break
      case "SKIPPED":
        this.skipped += 1
        this.write(skip('_'))
        break
      case "REJECTED":
        this.rejected.push(observation)
        this.write(error('x'))
        break
    }
  }

  log(report) {
    this.writeLine()
    this.writeLine()
    report.forEach(line => this.printReport(line, "", logMessage))
  }

  error(err) {
    this.writeLine("Error running spec suite!")
    this.writeLine()
    err.forEach(r => this.printReport(r))
    this.hasError = true
  }

  finish() {
    if (this.hasError) return

    this.writeLine("\n")
    this.writeLine(ok(`Accepted: ${this.accepted}`))
    if (this.skipped > 0) {
      this.writeLine(skip(`Skipped: ${this.skipped}`))
    }
    if (this.rejected.length > 0) {
      this.writeLine(error(`Rejected: ${this.rejected.length}`))
      this.rejected.forEach(o => this.printRejection(o))
    } else {
      this.writeLine()
    }
  }

  printConditions(conditions) {
    this.writeLine(`  ${conditions[0]}`)
    this.writeLine()
    this.writeLine(`  ${conditions[1]}`)
    conditions.slice(2).forEach((condition) => {
      this.writeLine(`    ${condition}`)
    })
  }

  printRejection(observation) {
    this.writeLine(error("\nFailed to satisfy spec:"))
    this.writeLine()
    this.printModulePath(observation.modulePath)
    this.printConditions(observation.conditions)
    this.writeLine(`    ${observation.description}`)
    this.writeLine()
    observation.report.forEach(r => this.printReport(r))
  }

  printReport(report, padding = "    ", render = error) {
    const statementLines = report.statement.split("\n")
    statementLines.forEach(line => {
      this.writeLine(render(`${padding}${line}`))
    })
    if (report.detail) {
      const detailLines = report.detail.split("\n")
      detailLines.forEach(line => {
        this.writeLine(render(`${padding}  ${line}`))
      })
    }
    this.writeLine()
  }

  printModulePath(modulePath) {
    this.writeLine(`  ${modulePath}`)
    this.writeLine()
  }
}

