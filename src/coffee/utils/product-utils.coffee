_ = require 'underscore'
_.mixin require('sphere-node-utils')._u
jsondiffpatch = require 'jsondiffpatch'
Utils = require './utils'
helper = require '../helper'

REGEX_NUMBER = new RegExp /^\d+$/
REGEX_UNDERSCORE_NUMBER = new RegExp /^\_\d+$/

###
Product Utils class
###
class ProductUtils extends Utils

  allVariants = (product) ->
    {masterVariant, variants} = _.defaults product,
      masterVariant: {}
      variants: []
    [masterVariant].concat variants

  diff: (old_obj, new_obj) ->
    # patch 'prices' to have an identifier in order for the diff
    # to be able to match nested objects in arrays
    # e.g.: prices: [ { _id: x, value: {} } ]
    patchPrices = (obj) ->
      _.each allVariants(obj), (variant) ->
        if variant.prices
          _.each variant.prices, (price, index) ->
            price._id = index

    patchPrices(old_obj)
    patchPrices(new_obj)

    isEnum = (value) -> _.has(value, 'key') and _.has(value, 'label')

    # setting an lenum via the API support only to set the key of the enum.
    # Thus we delete the original value (containing key and label) and set
    # the key as value at the attribute.
    # This way (l)enum attributes are handled the same way as text attributes.
    patchEnum = (attribute) ->
      return if _.isUndefined(attribute.value) or _.isNull(attribute.value)
      if isEnum attribute.value
        v = attribute.value.key
        delete attribute.value
        attribute.value = v
      else if _.isArray(attribute.value)
        for val, index in attribute.value
          if isEnum val
            attribute.value[index] = val.key
          else # if we can't find key and label it isn't an (l)enum set and we can stop immediately
            return

    patchEnums = (obj) ->
      _.each allVariants(obj), (variant) ->
        if variant.attributes
          _.each variant.attributes, (attrib, index) ->
            patchEnum attrib

    patchEnums(old_obj)
    patchEnums(new_obj)

    super(old_obj, new_obj)


  ###
  # Actions mapping
  ###
  actionsMapBase: (diff, old_obj) ->
    list = _.filter actionsBaseList(), (a) ->
      switch a.key
        when 'name', 'slug', 'description' then true
        else false
    actions = []
    _.each list, (item) ->
      action = buildBaseAttributesAction(item, diff, old_obj)
      actions.push action if action
    actions

  actionsMapMetaAttributes: (diff, old_obj) ->
    list = _.filter actionsBaseList(), (a) ->
      switch a.key
        when 'metaTitle', 'metaDescription', 'metaKeywords' then true
        else false
    actions = []
    _.each list, (item) ->
      action = buildBaseAttributesAction(item, diff, old_obj)
      actions.push action if action
    return [] if _.isEmpty actions
    # since there is only one action for each of those attributes, we can reduce them to one
    reduced = _.reduce actions, (memo, action) ->
      _.extend {}, memo, action
    , {action: 'setMetaAttributes'}
    defaults = _.pick old_obj, 'metaTitle', 'metaDescription', 'metaKeywords'
    [_.defaults(reduced, defaults)]

  actionsMapVariants: (diff, old_obj, new_obj) ->
    actions = []
    if diff.variants
      _.each diff.variants, (variant, key) ->
        if REGEX_NUMBER.test(key) and _.isArray(variant)
          newVariant = new_obj.variants[key]
          action =
            action: 'addVariant'
          action.sku = newVariant.sku if newVariant.sku
          action.prices = newVariant.prices if newVariant.prices
          action.attributes = newVariant.attributes if newVariant.attributes
          actions.push action
        else if REGEX_UNDERSCORE_NUMBER.test(key) and _.isArray(variant)
          action =
            action: 'removeVariant'
            id: variant[0].id
          actions.push action

    _.sortBy actions, (a) -> a.action is 'addVariant'

  actionsMapReferences: (diff, old_obj, new_obj) ->
    actions = []
    if diff.taxCategory
      if _.isArray diff.taxCategory
        action =
          action: 'setTaxCategory'
        action.taxCategory = helper.getDeltaValue diff.taxCategory
        actions.push action
      else
        action =
          action: 'setTaxCategory'
          taxCategory: new_obj.taxCategory
        actions.push action

    if diff.categories
      _.each diff.categories, (category) ->
        if _.isArray category
          action =
            category: category[0]
          if _.size(category) is 3
            action.action = 'removeFromCategory'
          else if _.size(category) is 1
            action.action = 'addToCategory'
          actions.push action

    _.sortBy actions, (a) -> a.action is 'addToCategory'

  actionsMapPrices: (diff, old_obj, new_obj) ->
    actions = []
    # masterVariant
    if diff.masterVariant
      prices = diff.masterVariant.prices
      if prices
        _.each prices, (value, key) ->
          if REGEX_NUMBER.test key
            # key is index of new price
            index = key
          else if REGEX_UNDERSCORE_NUMBER.test key
            # key is index of old price
            index = key.substring(1)

          if index
            if _.size(value) is 1 and _.size(value.value) is 1 and _.has(value.value, 'centAmount')
              changeAction = buildChangePriceAction(value.value.centAmount, old_obj.masterVariant, index)
              actions.push changeAction if changeAction
            else
              removeAction = buildRemovePriceAction(old_obj.masterVariant, index)
              actions.push removeAction if removeAction
              addAction = buildAddPriceAction(new_obj.masterVariant, index)
              actions.push addAction if addAction

    # variants
    if diff.variants
      _.each diff.variants, (variant, i) ->
        prices = variant.prices
        if prices
          _.each prices, (value, key) ->
            if REGEX_NUMBER.test key
              # key is index of new price
              index = key
            else if REGEX_UNDERSCORE_NUMBER.test key
              # key is index of old price
              index = key.substring(1)

            if index
              if _.size(value) is 1 and _.size(value.value) is 1 and _.has(value.value, 'centAmount')
                changeAction = buildChangePriceAction(value.value.centAmount, old_obj.variants[i], index)
                actions.push changeAction if changeAction
              else
                removeAction = buildRemovePriceAction(old_obj.variants[i], index)
                actions.push removeAction if removeAction
                addAction = buildAddPriceAction(new_obj.variants[i], index)
                actions.push addAction if addAction

    # this will sort the actions ranked in asc order (first 'remove' then 'add')
    _.sortBy actions, (a) -> a.action is 'addPrice'

  # we assume that the products have the same ProductType
  # TODO: validate ProductType between products
  actionsMapAttributes: (diff, old_obj, new_obj, sameForAllAttributeNames = []) ->
    actions = []
    # masterVariant
    masterVariant = diff.masterVariant
    if masterVariant
      skuAction = buildSkuActions(masterVariant, old_obj.masterVariant)
      actions.push(skuAction) if skuAction?
      attributes = masterVariant.attributes
      attrActions = buildVariantAttributesActions attributes, old_obj.masterVariant, new_obj.masterVariant, sameForAllAttributeNames
      actions = actions.concat attrActions

    # variants
    if diff.variants
      _.each diff.variants, (variant, i) ->
        skuAction = buildSkuActions(variant, old_obj.variants[i])
        actions.push(skuAction) if skuAction?
        attributes = variant.attributes
        attrActions = buildVariantAttributesActions attributes, old_obj.variants[i], new_obj.variants[i], sameForAllAttributeNames
        actions = actions.concat attrActions

    # Ensure we have each action only once per product. Use string representation of object to allow `===` on array objects
    _.unique actions, (action) -> JSON.stringify action

  actionsMapImages: (diff, old_obj, new_obj) ->
    actions = []
    # masterVariant
    masterVariant = diff.masterVariant
    if masterVariant
      mActions = buildVariantImagesAction masterVariant.images, old_obj.masterVariant, new_obj.masterVariant
      actions = actions.concat mActions

    # variants
    if diff.variants
      _.each diff.variants, (variant, i) ->
        vActions = buildVariantImagesAction variant.images, old_obj.variants[i], new_obj.variants[i]
        actions = actions.concat vActions

    # this will sort the actions ranked in asc order (first 'remove' then 'add')
    _.sortBy actions, (a) -> a.action is 'addExternalImage'


###
Exports object
###
module.exports = ProductUtils

#################
# Product helper methods
#################

actionsBaseList = ->
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
      action: 'setMetaAttributes'
      key: 'metaTitle'
    },
    {
      action: 'setMetaAttributes'
      key: 'metaDescription'
    },
    {
      action: 'setMetaAttributes'
      key: 'metaKeywords'
    }
  ]

buildBaseAttributesAction = (item, diff, old_obj) ->
  key = item.key
  obj = diff[key]
  if obj
    updated = {}
    if _.isArray obj
      updated = helper.getDeltaValue(obj)
    else
      keys = _.keys obj
      _.each keys, (k) ->
        value = helper.getDeltaValue(obj[k])
        updated[k] = value

    if old_obj[key]
      # extend values of original object with possible new values of the diffed object
      # e.g.:
      #   old = {en: 'foo'}
      #   updated = {de: 'bar', en: undefined}
      #   => old = {en: undefined, de: 'bar'}
      old = _.deepClone old_obj[key]
      _.extend old, updated
    else
      old = updated
    action =
      action: item.action
    if updated
      action[key] = old
    else
      action[key] = undefined
  action

buildChangePriceAction = (centAmountDiff, variant, index) ->
  price = variant.prices[index]
  if price
    delete price._id
    price.value.centAmount = helper.getDeltaValue(centAmountDiff)
    action =
      action: 'changePrice'
      variantId: variant.id
      price: price
  action

buildRemovePriceAction = (variant, index) ->
  price = variant.prices[index]
  if price
    delete price._id
    action =
      action: 'removePrice'
      variantId: variant.id
      price: price
  action

buildAddPriceAction = (variant, index) ->
  price = variant.prices[index]
  if price
    delete price._id
    action =
      action: 'addPrice'
      variantId: variant.id
      price: price
  action

buildVariantImagesAction = (images, old_variant, new_variant) ->
  actions = []
  _.each images, (img, key) ->
    if REGEX_NUMBER.test key
      unless _.isEmpty old_variant.images
        action = buildRemoveImageAction old_variant, old_variant.images[key]
        actions.push action if action
      unless _.isEmpty new_variant.images
        action = buildAddExternalImageAction old_variant, new_variant.images[key]
        actions.push action if action
    else if REGEX_UNDERSCORE_NUMBER.test key
      index = key.substring(1)
      unless _.isEmpty old_variant.images
        action = buildRemoveImageAction old_variant, old_variant.images[index]
        actions.push action if action
  actions

buildAddExternalImageAction = (variant, image) ->
  if image
    action =
      action: 'addExternalImage'
      variantId: variant.id
      image: image
  action

buildRemoveImageAction = (variant, image) ->
  if image
    action =
      action: 'removeImage'
      variantId: variant.id
      imageUrl: image.url
  action


buildSetAttributeAction = (diffed_value, old_variant, attribute, sameForAllAttributeNames) ->
  return unless attribute
  if attribute
    action =
      action: 'setAttribute'
      variantId: old_variant.id
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
        if _.has(diffed_value, '_t') and diffed_value['_t'] is 'a'
          # set-typed attribute
          action.value = attribute.value
        else
          # LText
          text = {}
          _.each diffed_value, (v, k) ->
            text[k] = helper.getDeltaValue(v)
          action.value = text

  action

buildNewSetAttributeAction = (id, el, sameForAllAttributeNames) ->
  attributeName = el.name
  return unless attributeName
  action =
    action: "setAttribute"
    variantId: id
    name: attributeName
    value: el.value
  if _.contains(sameForAllAttributeNames, attributeName)
    action.action = 'setAttributeInAllVariants'
    delete action.variantId
  action

buildVariantAttributesActions = (attributes, old_variant, new_variant, sameForAllAttributeNames) ->
  actions = []
  if attributes
    _.each attributes, (value, key) ->
      if REGEX_NUMBER.test key
        if _.isArray value
          v = helper.getDeltaValue(value)
          id = old_variant.id
          setAction = buildNewSetAttributeAction(id, v, sameForAllAttributeNames)
          actions.push setAction if setAction
        else
          # key is index of attribute
          index = key
          setAction = buildSetAttributeAction(value.value, old_variant, new_variant.attributes[index], sameForAllAttributeNames)
          actions.push setAction if setAction
      else if REGEX_UNDERSCORE_NUMBER.test key
        if _.isArray value
          # ignore pure array moves! TODO: remove when moving to new version of jsondiffpath (issue #9)
          if _.size(value) is 3 and value[2] is 3
            return
          v = helper.getDeltaValue(value)
          unless v
            v = value[0]
            delete v.value
          id = old_variant.id
          setAction = buildNewSetAttributeAction(id, v, sameForAllAttributeNames)
          actions.push setAction if setAction
        else
          index = key.substring(1)
          setAction = buildSetAttributeAction(value.value, old_variant, new_variant.attributes[index], sameForAllAttributeNames)
          actions.push setAction if setAction
  actions

buildSkuActions = (variantDiff, old_variant) ->
  if _.has variantDiff, 'sku'
    action =
      action: 'setSKU'
      variantId: old_variant.id
      sku: helper.getDeltaValue(variantDiff.sku)
