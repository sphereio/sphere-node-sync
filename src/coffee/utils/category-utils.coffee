_ = require 'underscore'
Utils = require './utils'
helper = require '../helper'

###
CategoryUtils Utils class
###
class CategoryUtils extends Utils

  ###
  Create list of actions for syncing categories.
  @param {object} diff result of jsondiffpatch tool.
  @return list with actions
  ###
  actionsMap: (diff) ->
    console.log "DIFF", diff
    actions = []
    _.each actionsList(), (item) ->
      key = item.key
      obj = diff[key]
      if obj?
        updated = helper.getDeltaValue obj
        action =
          action: item.action
        action[key] = updated

      actions.push action if action?
    actions


###
Exports object
###
module.exports = CategoryUtils

#################
# Category helper methods
#################

actionsList = ->
  [
    {
      action: 'changeName'
      key: 'name'
    },
    {
      action: 'changeSlug'
      key: 'slug'
    },
    {
      action: 'setDescription'
      key: 'description'
    },
    {
      action: 'changeParent'
      key: 'parent'
#    },
#    {
#      action: 'changeOrderHint'
#      key: 'orderHint'
    }
  ]

