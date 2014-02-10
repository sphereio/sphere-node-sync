_ = require("underscore")._
Rest = require("sphere-node-connect").Rest
Sync = require("../sync/sync")
OrderUtils = require("../utils/order-utils")

###
Order Sync class
###
class OrderSync extends Sync
  constructor: (opts = {}) ->
    super(opts)
    # Override base utils
    @_utils = new OrderUtils
    @

  _doMapActions: (diff, new_obj, old_obj) ->
    actionsStatus = @_utils.actionsMapStatusValues(diff, old_obj)
    actionsReturnInfo = @_utils.actionsMapReturnInfo(diff, old_obj)
    actionsDeliveries = @_utils.actionsMapDeliveries(diff, old_obj)
    _.union actionsStatus, actionsReturnInfo, actionsDeliveries

  _doUpdate: (callback) ->
    payload = JSON.stringify @_data.update
    @_rest.POST "/orders/#{@_data.updateId}", payload, callback


###
Exports object
###
module.exports = OrderSync