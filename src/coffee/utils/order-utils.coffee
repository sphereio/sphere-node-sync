_ = require("underscore")._
jsondiffpatch = require("jsondiffpatch")
Utils = require("./utils")
helper = require("../helper")

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

  actionMapReturnInfo: (diff, old_obj, new_obj) ->

    actions = []

    returnInfoDiff = diff['returnInfo']
    if returnInfoDiff
      if _.isArray returnInfoDiff
        # returnInfo was added
        returnInfo = _.first returnInfoDiff
        action =
            action: 'addReturnInfo'
        _.each _.keys(returnInfo), (key) ->
          action[key] = returnInfo[key]
        actions.push action
      else
        # returnInfo was updated
        if returnInfoDiff.items
          _.each _.keys(returnInfoDiff.items), (index) ->
            returnItem = returnInfoDiff.items[index]
            _.each actionsListReturnInfoState(), (actionDefinition) ->
              returnItemState = returnItem[actionDefinition.key]
              if returnItemState
                action = {}
                action["action"] = actionDefinition.action
                action["returnItemId"] = old_obj.returnInfo.items[index].id
                action[actionDefinition.key] = helper.getDeltaValue returnItemState
                actions.push action
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

actionsListReturnInfoState = ->
  [
    {
      action: "setReturnShipmentState"
      key: "shipmentState"
    },
    {
      action: "setReturnPaymentState"
      key: "paymentState"
    }
  ]
