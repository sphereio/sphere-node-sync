_ = require("underscore")._
Rest = require("sphere-node-connect").Rest
Sync = require("../sync/sync")
helper = require("../helper")

###
Invetory Sync class
###
class InventorySync extends Sync
  constructor: (opts = {})->
    super(opts)
    @

  _doMapActions: (diff, new_obj, old_obj)->
    actions = []
    if diff.quantityOnStock
      if _.isArray(diff.quantityOnStock) and _.size(diff.quantityOnStock) is 2
        oldVal = diff.quantityOnStock[0]
        newVal = diff.quantityOnStock[1]
        diffVal = newVal - oldVal
        a =
          quantity: Math.abs diffVal
        if diffVal > 0
          a.action = 'addQuantity'
          actions.push a
        else if diffVal < 0
          a.action = 'removeQuantity'
          actions.push a
    if diff.expectedDelivery
      if _.isArray(diff.expectedDelivery)
        size = _.size(diff.expectedDelivery)
        a =
          action: 'setExpectedDelivery'
        if size is 1
          a.expectedDelivery = diff.expectedDelivery[0]
        else if size is 2
          a.expectedDelivery = diff.expectedDelivery[1]
        # Delete case (size is 3) - we don not set any expectedDelivery
        actions.push a
    return actions

  _doUpdate: (callback)->
    payload = JSON.stringify @_data.update
    @_rest.POST "/inventory/#{@_data.updateId}", payload, callback

###
Exports object
###
module.exports = InventorySync