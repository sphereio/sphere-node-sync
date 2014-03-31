_ = require 'underscore'
{Rest} = require 'sphere-node-connect'
Sync = require '../sync/sync'
ProductUtils = require '../utils/product-utils'

###
Product Sync class
###
class ProductSync extends Sync
  constructor: (opts = {}) ->
    super(opts)
    # Override base utils
    @_utils = new ProductUtils

  buildActions: (new_obj, old_obj, sameForAllAttributeNames = []) ->
    @sameForAllAttributeNames = sameForAllAttributeNames
    super new_obj, old_obj

  _doMapActions: (diff, new_obj, old_obj) ->
    doAction = (type, fn) =>
      found = _.find @_syncConfig, (c) -> c.type is type
      switch found.group
        when 'black' then []
        else fn
    actionsBase = doAction 'base', @_utils.actionsMap(diff, old_obj)
    actionsReferences = doAction 'references', @_utils.actionsMapReferences(diff, old_obj, new_obj)
    actionsPrices = doAction 'prices', @_utils.actionsMapPrices(diff, old_obj, new_obj)
    actionsAttributes = doAction 'attributes', @_utils.actionsMapAttributes(diff, new_obj, @sameForAllAttributeNames)
    actionsImages = doAction 'images', @_utils.actionsMapImages(diff, old_obj, new_obj)
    actionsVariants = doAction 'variants', @_utils.actionsMapVariants(diff, old_obj, new_obj)
    actions = _.union actions, actionsReferences, actionsPrices, actionsAttributes, actionsImages, actionsVariants
    actions

  _doUpdate: (callback) ->
    payload = JSON.stringify @_data.update
    @_rest.POST "/products/#{@_data.updateId}", payload, callback


###
Exports object
###
module.exports = ProductSync
