_ = require("underscore")._
jsondiffpatch = require("jsondiffpatch")
Utils = require("../lib/utils")
helper = require("../lib/helper")

###
Order Utils class
###
class OrderUtils extends Utils

  # This is used assuming the keys are on the first level of the object
  actionsMapStatuses: (diff, old_obj)->
    actions = []
    _.each actionsList(), (item)->
      key = item.key
      obj = diff[key]
      if obj
        updated = helper.getDeltaValue(obj)
        action =
          action: item.action
        action[key] = updated

      actions.push action if action
    actions


###
Exports object
###
module.exports = OrderUtils

#################
# Order helper methods
#################

actionsList = ->
  [
    {
      action: "changeOrderState"
      key: "orderState"
    },
    {
      action: "changePaymentState"
      key: "paymentState"
    },
    {
      action: "changeShipmentState"
      key: "shipmentState"
    }
  ]
