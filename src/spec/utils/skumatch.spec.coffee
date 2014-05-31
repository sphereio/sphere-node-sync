ProductUtils = require '../../lib/utils/product-utils'

describe 'SKU based matching', ->
  beforeEach ->
    @utils = new ProductUtils
    @existingProduct =
      id: '123'
      variants: []

    @newProduct =
      id: '123'
      variants: []

  compareDiff = (utils, existingProduct, newProduct, expectedDelta) ->
    delta = utils.diff existingProduct, newProduct
    expect(delta).toEqual expectedDelta
    delta

  compareVariantActions = (utils, delta, existingProduct, newProduct, expectedVariantActions) ->
    update = utils.actionsMapVariants delta, existingProduct, newProduct
    expect(update).toEqual expectedVariantActions

  compareAttributeActions = (utils, delta, existingProduct, newProduct, expectedAttributeActions) ->
    update = utils.actionsMapAttributes delta, existingProduct, newProduct
    expect(update).toEqual expectedAttributeActions

  #compareAttributeActions = ()

  it 'should work with a new variant', ->
    @newProduct.variants = [
      { sku: 'v2', attributes: [{name: 'attrib', value: 'val'}] }
    ]

    delta = compareDiff @utils, @existingProduct, @newProduct, variants:
      0: [{ sku :'v2', attributes: [{ name: 'attrib', value: 'val' }], _MATCH_CRITERIA : 'v2', _NEW_ARRAY_INDEX: 0 }]
      _t: 'a'

    compareVariantActions @utils, delta, @existingProduct, @newProduct, [
      { action: 'addVariant', sku: 'v2', attributes: [{ name: 'attrib', value: 'val' }] }
    ]

    compareAttributeActions @utils, delta, @existingProduct, @newProduct, []

  it 'should work when removing a variant', ->
    @existingProduct.variants = [
      { id: 7, sku: 'vX', attributes: [{name: 'attrib', value: 'val'}] }
    ]
    
    delta = compareDiff @utils, @existingProduct, @newProduct, variants:
      _t: 'a'
      _0: [{ id: 7, sku :'vX', attributes: [{ name: 'attrib', value: 'val' }], _MATCH_CRITERIA : 'vX', _EXISTING_ARRAY_INDEX: 0 }, 0, 0]

    compareVariantActions @utils, delta, @existingProduct, @newProduct, [
      { action: 'removeVariant', id: 7 }
    ]

    compareAttributeActions @utils, delta, @existingProduct, @newProduct, []

  it 'should work when adding a new variant before others', ->
    @existingProduct.variants = [
      { id: 9, sku: 'v2', attributes: [{name: 'attrib', value: 'val'}] }
    ]
    
    @newProduct.variants = [
      { sku: 'vN', attributes: [{name: 'attribN', value: 'valN'}] }
      { sku: 'v2', attributes: [{name: 'attrib', value: 'CHANGED'}] }
    ]

    delta = compareDiff @utils, @existingProduct, @newProduct, variants:
      0: [{ sku :'vN', attributes: [{ name: 'attribN', value: 'valN' }], _MATCH_CRITERIA : 'vN', _NEW_ARRAY_INDEX: 0 }]
      1: { attributes : { 0: { value: ['val', 'CHANGED'] }, _t : 'a' }, id : [9, 0, 0], _NEW_ARRAY_INDEX: [1], _EXISTING_ARRAY_INDEX: [0, 0, 0] }
      _t: 'a'

    compareVariantActions @utils, delta, @existingProduct, @newProduct,  [
      { action: 'addVariant', sku: 'vN', attributes: [{name: 'attribN', value: 'valN'}] }
    ]

    compareAttributeActions @utils, delta, @existingProduct, @newProduct, [
      { action : 'setAttribute', variantId : 9, name : 'attrib', value : 'CHANGED' }
    ]

  it 'should work when the order of variant has changed', ->
    @existingProduct.variants = [
      { id: 2, sku: 'v2', attributes: [{name: 'attrib2', value: 'val2'}] }
      { id: 3, sku: 'v3', attributes: [{name: 'attrib3', value: 'val3'}] }
    ]
    
    @newProduct.variants = [
      { id: 2, sku: 'v3', attributes: [{name: 'attrib3', value: 'val3'}] }
      { id: 3, sku: 'v2', attributes: [{name: 'attrib2', value: 'val2'}] }
    ]

    delta = compareDiff @utils, @existingProduct, @newProduct, variants:
      0: { id: [3, 2], _NEW_ARRAY_INDEX: [0], _EXISTING_ARRAY_INDEX: [1, 0, 0] }
      1: { id: [2, 3], _NEW_ARRAY_INDEX: [1], _EXISTING_ARRAY_INDEX: [0, 0, 0] }
      _t: 'a'
      _1 : ['', 0, 3]

    compareVariantActions @utils, delta, @existingProduct, @newProduct,  []

    compareAttributeActions @utils, delta, @existingProduct, @newProduct, []