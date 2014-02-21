_ = require('underscore')._
jsondiffpatch = require 'jsondiffpatch'
Utils = require './utils'
helper = require '../helper'

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
    deliveriesDiffs = diff.shippingInfo.deliveries if diff.shippingInfo
    if deliveriesDiffs
      # iterate over returnInfo instances
      _.each _.keys(deliveriesDiffs), (deliveryIndex) ->
        if deliveryIndex isnt '_t'
          deliveryDiff = deliveriesDiffs[deliveryIndex]
          if _.isArray deliveryDiff
            # delivery was added
            delivery = _.last deliveryDiff
            action =
              action: 'addDelivery'
            _.each _.keys(delivery), (key) ->
              action[key] = delivery[key]
            actions.push action

          else
            # iterate over parcel instances
            _.each _.keys(deliveryDiff.parcels), (parcelIndex) ->
              if parcelIndex  isnt '_t'
                parcelDiff = deliveryDiff.parcels[parcelIndex]

                if _.isArray parcelDiff
                  # delivery was added
                  parcel = _.last parcelDiff
                  action =
                    action: 'addParcelToDelivery'
                    deliveryId: old_obj.shippingInfo.deliveries[deliveryIndex].id
                  _.each _.keys(parcel), (key) ->
                    action[key] = parcel[key]
                  actions.push action
    actions




  ###
  Create list of actions for syncing returnInfo items and returnInfo status values.
  @param {object} diff Result of jsondiffpatch tool.
  @param {object} old_obj Order to be updated.
  @return list with actions
  ###
  actionsMapReturnInfo: (diff, old_obj) ->

    actions = []
    returnInfoDeltas = diff['returnInfo']
    if returnInfoDeltas
      # iterate over returnInfo instances
      _.chain returnInfoDeltas
        .filter (item, key) -> key isnt '_t'
        .map (returnInfoDelta, returnInfoDeltaKey) ->
          if _.isArray returnInfoDelta
            # get last added item
            returnInfo = _.last returnInfoDelta
            action =
              action: 'addReturnInfo'
            _.each returnInfo, (value, key) ->
              action[key] = value
            actions.push action

            # TODO: split into multiple actions (addReturnInfo + setReturnShipmentState/setReturnPaymentState)
            #   in case shipmentState/paymentState already transitioned to a non-initial state
          else
            returnInfo = returnInfoDelta
            # iterate over returnItem instances
            actions = _.chain returnInfo.items
              .filter (item, key) -> key isnt '_t'
              .map (item, itemKey) ->
                # iterate over all returnInfo status actions
                _.chain actionsListReturnInfoState()
                  .filter (actionDefinition) -> _.has(item, actionDefinition.key)
                  .map (actionDefinition) ->
                    action =
                      action: actionDefinition.action
                      returnItemId: old_obj.returnInfo[returnInfoDeltaKey].items[itemKey].id
                    action[actionDefinition.key] = helper.getDeltaValue item[actionDefinition.key]
                    action
                  .value()
              .value()
       .value()
    _.flatten actions

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
