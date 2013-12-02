_ = require("underscore")._
Rest = require("sphere-node-connect").Rest
Utils = require("../lib/utils")

###
Base Sync class
###
class Sync
  constructor: (opts = {})->
    unless _.isEmpty opts
      config = opts.config
      throw new Error("Missing credentials") unless config
      throw new Error("Missing 'client_id'") unless config.client_id
      throw new Error("Missing 'client_secret'") unless config.client_secret
      throw new Error("Missing 'project_key'") unless config.project_key
      @_rest = new Rest opts

    @_data = {}
    @_utils = new Utils
    @

  buildActions: (new_obj, old_obj)->
    # diff 'em
    diff = @_utils.diff(old_obj, new_obj)
    update = undefined
    if diff
      actions = @_doMapActions(diff, new_obj, old_obj)
      if actions.length > 0
        update =
          actions: actions
          version: old_obj.version
    @_data =
      update: update
      updateId: old_obj.id
    @

  get: (key = "update")-> @_data[key]

  update: (callback)->
    throw new Error("Cannot update: the Rest connector wasn't instantiated (probabily because of missing credentials)") unless @_rest
    unless _.isEmpty @_data.update
      @_doUpdate(callback)
    else
      # nothing to update
      callback(null, statusCode: 304, null)

  ###
  Methods to override
  ###
  _doMapActions: (diff, new_obj, old_obj)->
    # => Override to map actions
    []

  _doUpdate: (callback)->
    # => Override to send update request
    callback(null, null, null)

###
Exports object
###
module.exports = Sync