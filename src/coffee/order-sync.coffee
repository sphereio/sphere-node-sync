_ = require("underscore")._
Rest = require("sphere-node-connect").Rest
Sync = require("../lib/sync")
OrderUtils = require("../lib/order-utils")

###
Order Sync class
###
class OrderSync extends Sync
  constructor: (opts = {})->
    super(opts)
    # Override base utils
    @_utils = new OrderUtils
    @

  _doMapActions: (diff, new_obj, old_obj)->
    actions = @_utils.actionsMapStatuses(diff, old_obj)
    actions

  _doUpdate: (callback)->
    payload = JSON.stringify @_data.update
    @_rest.POST "/orders/#{@_data.updateId}", payload, callback


###
Exports object
###
module.exports = OrderSync