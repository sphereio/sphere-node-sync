_ = require('underscore')._
{Rest} = require 'sphere-node-connect'
Logger = require '../logger'
Utils = require '../utils/utils'

###
Base Sync class
###
class Sync
  constructor: (opts = {}) ->
    @_logger = new Logger opts.logConfig

    unless _.isEmpty opts
      config = opts.config
      throw new Error('Missing credentials') unless config
      throw new Error('Missing \'client_id\'') unless config.client_id
      throw new Error('Missing \'client_secret\'') unless config.client_secret
      throw new Error('Missing \'project_key\'') unless config.project_key
      @_rest = new Rest _.extend opts,
        logConfig:
          logger: @_logger

    @_logger.debug opts, "New #{@constructor.name} object"
    @_data = {}
    @_utils = new Utils

  buildActions: (new_obj, old_obj) ->
    # diff 'em
    diff = @_utils.diff(old_obj, new_obj)
    @_logger.debug diff, "JSON diff for #{@constructor.name} object"
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
    @_logger.debug @_data, "Data update for #{@constructor.name} object"
    this

  filterActions: (fn) ->
    return this unless fn
    filtered = _.filter @_data.update.actions, fn
    @_data.update.actions = filtered
    this

  get: (key = 'update') -> @_data[key]

  update: (callback) ->
    unless @_rest
      throw new Error 'Cannot update: the Rest connector wasn\'t instantiated (probabily because of missing credentials)'
    unless _.isEmpty @_data.update
      @_doUpdate(callback)
    else
      # nothing to update
      callback(null, statusCode: 304, null)

  ###
  Methods to override
  ###
  _doMapActions: (diff, new_obj, old_obj) ->
    # => Override to map actions
    []

  _doUpdate: (callback) ->
    # => Override to send update request
    callback(null, null, null)

###
Exports object
###
module.exports = Sync
