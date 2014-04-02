_ = require 'underscore'
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

  _doUpdate: -> @_client.inventoryEntries.byId(@_data.updateId).update(@_data.update)

###
Exports object
###
module.exports = InventorySync
