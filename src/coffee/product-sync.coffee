_ = require("underscore")._
Rest = require("sphere-node-connect").Rest
Sync = require("../lib/sync")
ProductUtils = require("../lib/product-utils")

###
Product Sync class
###
class ProductSync extends Sync
  constructor: (opts = {})->
    super(opts)
    # Override base utils
    @_utils = new ProductUtils
    @

  _doMapActions: (diff, new_obj, old_obj)->
    actions = @_utils.actionsMap(diff, old_obj)
    actionsPrices = @_utils.actionsMapPrices(diff, old_obj, new_obj)
    actionsAttributes = @_utils.actionsMapAttributes(diff, new_obj)
    actions = _.union actions, actionsPrices, actionsAttributes
    actions

  _doUpdate: (callback)->
    payload = JSON.stringify @_data.update
    @_rest.POST "/products/#{@_data.updateId}", payload, callback


###
Exports object
###
module.exports = ProductSync