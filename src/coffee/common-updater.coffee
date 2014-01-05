_ = require('underscore')._
ProgressBar = require 'progress'
logentries = require 'node-logentries'

###
(abstract) Common Updater class
###
class CommonUpdater
  constructor: (options = {}) ->
    if options.logentries_token
      @log = logentries.logger token: options.logentries_token
    @showProgressBar = true if options.show_progress is true
    @

  initProgressBar: (title, size) ->
    if @showProgressBar
      @bar = new ProgressBar "#{title} [:bar] :current/:total (= :percent) done", { width: 80, total: size }

  tickProgress: () ->
    @bar.tick() if @bar

  returnResult: (isPossitive, message, callback) ->
    @bar.terminate() if @bar
    if _.isArray(message)
      if _.size(message) is 1
        message = message[0]
      else
        summary = {}
        for msg in message
          summary[msg] = 0 unless summary[msg]
          summary[msg] = summary[msg] + 1
        message = summary
    retVal =
      component: this.constructor.name
      status: isPossitive
      message: message
    if @log
      logLevel = if isPossitive then 'info' else 'err'
      @log.log logLevel, retVal
    callback retVal

###
Exports object
###
module.exports = CommonUpdater