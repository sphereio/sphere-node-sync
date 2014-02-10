_ = require('underscore')._
jsondiffpatch = require('jsondiffpatch')
Utils = require('./utils')
helper = require('../helper')

###
Order Utils class
###
class OrderUtils extends Utils

  ###
  Create list of actions for syncing order status values.
  @param {object} diff Result of jsondiffpatch tool.
  @param {object} old_obj Order to be updated.
  @return list with actions
  ###
  actionsMapStatusValues: (diff, old_obj) ->
    actions = []
    _.each actionsList(), (item) ->
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
  Create list of actions for syncing delivery items.
  @param {object} diff Result of jsondiffpatch tool.
  @param {object} old_obj Order to be updated.
  @return list with actions
  ###
  actionsMapDeliveries: (diff, old_obj) ->
    actions = []


  ###
  Create list of actions for syncing returnInfo items and returnInfo status values.
  @param {object} diff Result of jsondiffpatch tool.
  @param {object} old_obj Order to be updated.
  @return list with actions
  ###
  actionsMapReturnInfo: (diff, old_obj) ->

    actions = []
    returnInfoDiffs = diff['returnInfo']
    if returnInfoDiffs
      # iterate over returnInfo instances
      _.each _.keys(returnInfoDiffs), (returnInfoIndex) ->
        if returnInfoIndex != '_t'
          returnInfoDiff = returnInfoDiffs[returnInfoIndex]
          if _.isArray returnInfoDiff
            # returnInfo was added
            returnInfo = _.last returnInfoDiff
            action =
              action: 'addReturnInfo'
            _.each _.keys(returnInfo), (key) ->
              action[key] = returnInfo[key]
            actions.push action

            # TODO: split into multiple actions (addReturnInfo + setReturnShipmentState/setReturnPaymentState)
            #   in case shipmentState/paymentState already transitioned to a non-initial state
          else
            returnInfo = returnInfoDiff
            # iterate over returnInfo items instances
            _.each _.keys(returnInfo.items), (returnInfoItemIndex) ->
              if returnInfoItemIndex != '_t'
                returnInfoItem = returnInfo.items[returnInfoItemIndex]
                # iterate over all returnInfo status actions
                _.each actionsListReturnInfoState(), (actionDefinition) ->
                  returnItemState = returnInfoItem[actionDefinition.key]
                  if returnItemState
                    action = {}
                    action['action'] = actionDefinition.action
                    action['returnItemId'] = old_obj.returnInfo[returnInfoIndex].items[returnInfoItemIndex].id
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
      action: 'changeOrderState'
      key: 'orderState'
    },
    {
      action: 'changePaymentState'
      key: 'paymentState'
    },
    {
      action: 'changeShipmentState'
      key: 'shipmentState'
    }
  ]

actionsListReturnInfoState = ->
  [
    {
      action: 'setReturnShipmentState'
      key: 'shipmentState'
    },
    {
      action: 'setReturnPaymentState'
      key: 'paymentState'
    }
  ]
