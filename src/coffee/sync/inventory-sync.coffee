_ = require('underscore')._
{Rest} = require 'sphere-node-connect'
Sync = require '../sync/sync'
InventoryUtils = require '../utils/inventory-utils'

###
Inventory Sync class.
  Ensures that quantityOnStock and expectedDelivery is in sync.
###
class InventorySync extends Sync
  constructor: (opts = {}) ->
    super(opts)
    # Override base utils
    @_utils = new InventoryUtils

  _doMapActions: (diff, new_obj, old_obj) ->
    allActions = []
    allActions.push @_mapActionOrNot 'quantity', => @_utils.actionsMapQuantity(diff, old_obj)
    allActions.push @_mapActionOrNot 'expectedDelivery', => @_utils.actionsMapExpectedDelivery(diff, old_obj)
    _.flatten allActions

  _doUpdate: (callback) ->
    payload = JSON.stringify @_data.update
    @_rest.POST "/inventory/#{@_data.updateId}", payload, callback

###
Exports object
###
module.exports = InventorySync
