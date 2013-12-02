_ = require("underscore")._
Rest = require("sphere-node-connect").Rest
ProductUtils = require("../lib/product-utils").ProductUtils

# Define ProductSync object
exports.ProductSync = (opts = {})->
  unless _.isEmpty opts
    config = opts.config
    throw new Error("Missing credentials") unless config
    throw new Error("Missing 'client_id'") unless config.client_id
    throw new Error("Missing 'client_secret'") unless config.client_secret
    throw new Error("Missing 'project_key'") unless config.project_key
    @_rest = new Rest opts

  @_data = {}
  @_utils = new ProductUtils
  return

exports.ProductSync.prototype.buildActions = (new_obj, old_obj)->
  # diff 'em
  diff = @_utils.diff(old_obj, new_obj)
  update = undefined
  if diff
    actions = @_utils.actionsMap(diff, old_obj)
    actionsPrices = @_utils.actionsMapPrices(diff, old_obj, new_obj)
    actionsAttributes = @_utils.actionsMapAttributes(diff, new_obj)
    actions = _.union actions, actionsPrices, actionsAttributes
    if actions.length > 0
      update =
        actions: actions
        version: old_obj.version
  @_data =
    update: update
    updateId: old_obj.id
  @

exports.ProductSync.prototype.get = (key = "update")-> @_data[key]

exports.ProductSync.prototype.update = (callback)->
  throw new Error("Cannot update: the Rest connector wasn't instantiated (probabily because of missing credentials)") unless @_rest
  unless _.isEmpty @_data.update
    payload = JSON.stringify @_data.update
    @_rest.POST "/products/#{@_data.updateId}", payload, callback
  else
    # nothing to update
    # TODO: better notification
    callback(null, statusCode: 304, null)
