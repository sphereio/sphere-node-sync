_ = require("underscore")._
jsondiffpatch = require("jsondiffpatch")
Utils = require("./utils")
helper = require("../helper")

###
Product Utils class
###
class ProductUtils extends Utils
  diff: (old_obj, new_obj)->
    # patch 'prices' to have an identifier in order for the diff
    # to be able to match nested objects in arrays
    # e.g.: prices: [ { _id: x, value: {} } ]
    patchPrices = (obj)->
      if obj.masterVariant
        if obj.masterVariant.prices and obj.masterVariant.prices.length > 0
          _.each obj.masterVariant.prices, (p, i)-> p._id = i
      if obj.variants and obj.variants.length > 0
        _.each obj.variants, (v)->
          if v.prices and v.prices.length > 0
            _.each v.prices, (p, i)-> p._id = i
    patchPrices(old_obj)
    patchPrices(new_obj)

    # setting an lenum via the API support only to set the key of the enum.
    # Thus we delete the original value (containing key and label) and set
    # the key as value at the attribute.
    # This way (l)enum attributes are handled the same way as text attributes.
    patchEnum = (attribute) ->
      if _.has(attribute.value, 'key') and _.has(attribute.value, 'label')
        v = attribute.value.key
        delete attribute.value
        attribute.value = v

    patchEnums = (obj) ->
      if obj.masterVariant
        if obj.masterVariant.attributes
          _.each obj.masterVariant.attributes, (attrib, index) ->
            patchEnum attrib
      if obj.variants
        _.each obj.variants, (variant)->
          if variant.attributes
            _.each variant.attributes, (attrib, index) ->
              patchEnum attrib

    patchEnums(old_obj)
    patchEnums(new_obj)

    super(old_obj, new_obj)


  # This is used assuming the keys are on the first level of the object
  actionsMap: (diff, old_obj)->
    actions = []
    _.each actionsList(), (item)->
      key = item.key
      action = switch key
        when "name", "slug", "description"
          obj = diff[key]
          if obj
            updated = {}
            if _.isArray obj
              updated = helper.getDeltaValue(obj)
            else
              keys = _.keys obj
              _.each keys, (k)->
                value = helper.getDeltaValue(obj[k])
                updated[k] = value
            # extend values of original object so that the new value is saved
            old = _.clone old_obj[key]
            _.extend old, updated
            a =
              action: item.action
            if updated
              a[key] = old
            else
              a[key] = undefined
            a
      actions.push action if action
    actions

  actionsMapPrices: (diff, old_obj, new_obj)->
    actions = []
    # masterVariant
    if diff.masterVariant
      prices = diff.masterVariant.prices
      if prices
        _.each prices, (value, key)->
          if key.match(/^\d$/g)
            # key is index of new price
            index = key
          else if key.match(/^\_\d$/g)
            # key is index of old price
            index = key.substring(1)

          if index
            removeAction = buildRemovePriceAction(old_obj.masterVariant, index)
            actions.push removeAction if removeAction
            addAction = buildAddPriceAction(new_obj.masterVariant, index)
            actions.push addAction if addAction

    # variants
    if diff.variants
      _.each diff.variants, (variant, i)->
        prices = variant.prices
        if prices
          _.each prices, (value, key)->
            if key.match(/^\d$/g)
              # key is index of new price
              index = key
            else if key.match(/^\_\d$/g)
              # key is index of old price
              index = key.substring(1)

            if index
              removeAction = buildRemovePriceAction(old_obj.variants[i], index)
              actions.push removeAction if removeAction

              addAction = buildAddPriceAction(new_obj.variants[i], index)
              actions.push addAction if addAction

    # this will sort the actions ranked in asc order (first 'remove' then 'add')
    _.sortBy actions, (a)-> a.action is "addPrice"

  actionsMapVariantAttributes = (attributes, variant, sameForAllAttributeNames) ->
    actions = []
    if attributes
      _.each attributes, (value, key) ->
        if key.match(/^\d$/g)
          if _.isArray value
            v = helper.getDeltaValue(value)
            id = variant.id
            setAction = buildNewSetAttributeAction(id, v)
            actions.push setAction if setAction
          else
            # key is index of attribute
            index = key
            setAction = buildSetAttributeAction(value.value, variant, index, sameForAllAttributeNames)
            actions.push setAction if setAction
        else if key.match(/^\_\d$/g)
          if _.isArray value
            v = helper.getDeltaValue(value)
            unless v
              v = value[0]
              delete v.value
            id = variant.id
            setAction = buildNewSetAttributeAction(id, v)
            actions.push setAction if setAction
          else
            index = key.substring(1)
            setAction = buildSetAttributeAction(value.value, variant, index, sameForAllAttributeNames)
            actions.push setAction if setAction

    actions

  # we assume that the products have the same ProductType
  # TODO: validate ProductType between products
  actionsMapAttributes: (diff, new_obj, sameForAllAttributeNames = []) ->
    actions = []
    # masterVariant
    masterVariant = diff.masterVariant
    if masterVariant
      attributes = masterVariant.attributes
      mActions = actionsMapVariantAttributes attributes, new_obj.masterVariant, sameForAllAttributeNames
      actions = actions.concat mActions

    # variants
    if diff.variants
      _.each diff.variants, (variant, i)->
        attributes = variant.attributes
        vActions = actionsMapVariantAttributes attributes, new_obj.variants[i], sameForAllAttributeNames
        actions = actions.concat vActions

    actions

###
Exports object
###
module.exports = ProductUtils

#################
# Product helper methods
#################

actionsList = ->
  [
    {
      action: "changeName"
      key: "name"
    },
    {
      action: "changeSlug"
      key: "slug"
    },
    {
      action: "setDescription"
      key: "description"
    }
  ]

buildRemovePriceAction = (variant, index)->
  price = variant.prices[index]
  if price
    delete price._id
    action =
      action: "removePrice"
      variantId: variant.id
      price: price
  action

buildAddPriceAction = (variant, index)->
  price = variant.prices[index]
  if price
    delete price._id
    action =
      action: "addPrice"
      variantId: variant.id
      price: price
  action

buildSetAttributeAction = (diffed_value, variant, index, sameForAllAttributeNames)->
  attribute = variant.attributes[index]
  if attribute
    action =
      action: "setAttribute"
      variantId: variant.id
      name: attribute.name
    if _.contains(sameForAllAttributeNames, attribute.name)
      action.action = 'setAttributeInAllVariants'
      delete action.variantId
    if _.isArray(diffed_value)
      action.value = helper.getDeltaValue(diffed_value)
    else
      # LText: value: {en: "", de: ""}
      # Money: value: {centAmount: 123, currencyCode: ""}
      # *: value: ""
      if _.isString(diffed_value)
        # normal
        action.value = helper.getDeltaValue(diffed_value)
      else if diffed_value.centAmount
        # Money
        if diffed_value.centAmount
          centAmount = helper.getDeltaValue(diffed_value.centAmount)
        else
          centAmount = attribute.value.centAmount
        if diffed_value.currencyCode
          currencyCode = helper.getDeltaValue(diffed_value.currencyCode)
        else
          currencyCode = attribute.value.currencyCode
        action.value =
          centAmount: centAmount
          currencyCode: currencyCode
      else if _.isObject(diffed_value)
        # LText
        text = {}
        _.each diffed_value, (v, k)->
          text[k] = helper.getDeltaValue(v)
        action.value = text

  action

buildNewSetAttributeAction = (id, el, sameForAllAttributeNames)->
  attributeName = el.name
  action =
    action: "setAttribute"
    variantId: id
    name: attributeName
    value: el.value
  if _.contains(sameForAllAttributeNames, attributeName)
    action.action = 'setAttributeInAllVariants'
    delete action.variantId
  action
