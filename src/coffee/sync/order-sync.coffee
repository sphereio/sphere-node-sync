_ = require 'underscore'
Sync = require '../sync/sync'
OrderUtils = require '../utils/order-utils'

###
Order Sync class
###
class OrderSync extends Sync
  constructor: (opts = {}) ->
    super(opts)
    # Override base utils
    @_utils = new OrderUtils

  _doMapActions: (diff, new_obj, old_obj) ->
    allActions = []
    allActions.push @_mapActionOrNot 'status', => @_utils.actionsMapStatusValues(diff, old_obj)
    allActions.push @_mapActionOrNot 'returnInfo', => @_utils.actionsMapReturnInfo(diff, old_obj)
    allActions.push @_mapActionOrNot 'deliveries', => @_utils.actionsMapDeliveries(diff, old_obj)
    _.flatten allActions

  _doUpdate: (callback) ->
    payload = JSON.stringify @_data.update
    @_rest.POST "/orders/#{@_data.updateId}", payload, callback


###
Exports object
###
module.exports = OrderSync
