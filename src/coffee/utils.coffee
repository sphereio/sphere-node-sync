_ = require("underscore")._
jsondiffpatch = require("jsondiffpatch")

exports.Utils = -> #noop

exports.Utils.prototype.diff = (old_obj, new_obj)->
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

  # provide a hash function to work with objects in arrays
  jsondiffpatch.config.objectHash = (obj)-> obj.id or obj._id or obj.name
  jsondiffpatch.diff(old_obj, new_obj)

# This is used assuming the keys are on the first level of the object
exports.Utils.prototype.actionsMap = (diff, old_obj)->
  actions = []
  _.each actionsList(), (item)->
    key = item.key
    action = switch key
      when "name", "slug", "description"
        obj = diff[key]
        if obj
          updated = {}
          if _.isArray obj
            updated = getDeltaValue(obj)
          else
            keys = _.keys obj
            _.each keys, (k)->
              value = getDeltaValue(obj[k])
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

exports.Utils.prototype.actionsMapPrices = (diff, old_obj, new_obj)->
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

# we assume that the products have the same ProductType
# TODO: validate ProductType between products
exports.Utils.prototype.actionsMapAttributes = (diff, new_obj)->
  actions = []
  # masterVariant
  masterVariant = diff.masterVariant
  if masterVariant
    attributes = masterVariant.attributes
    if attributes
      _.each attributes, (value, key)->
        if key.match(/^\d$/g)
          if _.isArray value
            v = getDeltaValue(value)
            id = new_obj.masterVariant.id
            setAction = buildNewSetAttributeAction(id, v)
            actions.push setAction if setAction
          else
            # key is index of attribute
            index = key
            setAction = buildSetAttributeAction(value.value, new_obj.masterVariant, index)
            actions.push setAction if setAction

  # variants
  if diff.variants
    _.each diff.variants, (variant, i)->
      attributes = variant.attributes
      if attributes
        _.each attributes, (value, key)->
          if key.match(/^\d$/g)
            if _.isArray value
              v = getDeltaValue(value)
              id = new_obj.variants[i].id
              setAction = buildNewSetAttributeAction(id, v)
              actions.push setAction if setAction
            else
              # key is index of attribute
              index = key
              setAction = buildSetAttributeAction(value.value, new_obj.variants[i], index)
              actions.push setAction if setAction
          else if key.match(/^\_\d$/g)
            if _.isArray value
              v = getDeltaValue(value)
              unless v
                v = value[0]
                delete v.value
              id = new_obj.variants[i].id
              setAction = buildNewSetAttributeAction(id, v)
              actions.push setAction if setAction
            else
              index = key.substring(1)
              setAction = buildSetAttributeAction(value.value, new_obj.variants[i], index)
              actions.push setAction if setAction

  actions


#################
# Helper methods
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

getDeltaValue = (arr)->
  size = arr.length
  switch size
    when 1 #new
      arr[0]
    when 2 #update
      arr[1]
    when 3 #delete
      undefined

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

buildSetAttributeAction = (diffed_value, variant, index)->
  attribute = variant.attributes[index]
  if attribute
    action =
      action: "setAttribute"
      variantId: variant.id
      name: attribute.name
    if _.isArray(diffed_value)
      action.value = getDeltaValue(diffed_value)
    else
      # LText: value: {en: "", de: ""}
      # Enum: value: {label: "", key: ""}
      # LEnum: value: {label: {en: "", de: ""}, key: ""}
      # Money: value: {centAmount: 123, currencyCode: ""}
      # *: value: ""
      if _.isString(diffed_value)
        # normal
        action.value = getDeltaValue(diffed_value)
      else if diffed_value.label
        # enum
        lab = diffed_value.label
        if _.isArray(lab)
          # Enum
          label = getDeltaValue(lab)
        else
          # LEnum
          label = {}
          _.each lab, (v, k)->
            label[k] = getDeltaValue(v)
        action.value =
          label: label
          key: getDeltaValue(diffed_value.key) or attribute.value.key
      else if diffed_value.centAmount
        # Money
        if diffed_value.centAmount
          centAmount = getDeltaValue(diffed_value.centAmount)
        else
          centAmount = attribute.value.centAmount
        if diffed_value.currencyCode
          currencyCode = getDeltaValue(diffed_value.currencyCode)
        else
          currencyCode = attribute.value.currencyCode
        action.value =
          centAmount: centAmount
          currencyCode: currencyCode
      else
        if diffed_value.key
          # enum without a label change
          action.value =
            label: attribute.value.label
            key: getDeltaValue(diffed_value.key)
        else
          # LText
          text = {}
          _.each diffed_value, (v, k)->
            text[k] = getDeltaValue(v)
          action.value = text

  action

buildNewSetAttributeAction = (id, el)->
  action =
    action: "setAttribute"
    variantId: id
    name: el.name
    value: el.value
  action
