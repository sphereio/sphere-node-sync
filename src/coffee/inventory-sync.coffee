_ = require("underscore")._
Rest = require("sphere-node-connect").Rest
Sync = require("../lib/sync")
helper = require("../lib/helper")

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
    return actions

  _doUpdate: (callback)->
    payload = JSON.stringify @_data.update
    @_rest.POST "/inventory/#{@_data.updateId}", payload, callback

###
Exports object
###
module.exports = InventorySync