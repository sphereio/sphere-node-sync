_ = require 'underscore'
SphereClient = require 'sphere-node-client'
Logger = require '../logger'
Utils = require '../utils/utils'

###
Base Sync class
###
class Sync
  constructor: (opts = {}) ->
    @_logger = new Logger opts.logConfig

    unless _.isEmpty opts
      @_client = new SphereClient _.extend opts,
        logConfig:
          logger: @_logger

    @_logger.debug opts, "New #{@constructor.name} object"
    @_data = {}
    @_utils = new Utils
    @_syncConfig = []

  config: (opts) ->
    @_syncConfig = opts or []
    this

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
    return this unless @_data.update
    filtered = _.filter @_data.update.actions, fn
    if _.isEmpty filtered
      @_data.update = undefined
    else
      @_data.update.actions = filtered
    this

  get: (key = 'update') -> @_data[key]

  update: (callback) ->
    unless @_client
      throw new Error 'Cannot update: the Rest connector wasn\'t instantiated (probabily because of missing credentials)'
    unless _.isEmpty @_data.update
      @_doUpdate(callback)
    else
      # nothing to update
      callback(null, statusCode: 304, null)

  _mapActionOrNot: (type, fn) ->
    return fn() if _.isEmpty @_syncConfig
    found = _.find @_syncConfig, (c) -> c.type is type
    return [] unless found
    switch found.group
      when 'black' then []
      when 'white' then fn()
      else throw new Error "Action group '#{found.group}' not supported. Please use black or white."

  ###
  Methods to override
  ###
  _doMapActions: (diff, new_obj, old_obj) ->
    # => Override to map actions
    []

  _doUpdate: ->
    # => Override to send update request
    Q()

###
Exports object
###
module.exports = Sync
