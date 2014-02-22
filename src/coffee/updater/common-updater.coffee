_ = require('underscore')._
ProgressBar = require 'progress'
logentries = require 'node-logentries'

###
(abstract) Common Updater class
  This class can be used by any connector to SPHERE.IO.
  It will ensure that the results have an equalant format.
  Further it provides methods for dealing with a progress bar.
###
class CommonUpdater
  constructor: (options = {}) ->
    if options.logentries_token
      @log = logentries.logger token: options.logentries_token
    @showProgressBar = options.show_progress

  initProgressBar: (title, size) ->
    if @showProgressBar
      @bar = new ProgressBar "#{title} [:bar] :current/:total (= :percent) done", { width: 80, total: size }

  tickProgress: -> @bar.tick() if @bar

  returnResult: (isPositive, message, callback) ->
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
      component: @constructor.name
      status: isPositive
      message: message
    if @log
      logLevel = if isPositive then 'info' else 'err'
      @log.log logLevel, retVal
      @log.end()
    callback retVal

###
Exports object
###
module.exports = CommonUpdater
