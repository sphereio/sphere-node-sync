_ = require 'underscore'
_.mixin deepClone: (obj) -> JSON.parse(JSON.stringify(obj))
InventoryUtils = require '../../lib/utils/inventory-utils'

INVENTORY =
  id: '123'
  sku: '123'
  quantityOnStock: 7

describe 'OrderUtils.actionsMapQuantity', ->
  beforeEach ->
    @utils = new InventoryUtils
    @inventory = _.deepClone INVENTORY

  afterEach ->
    @utils = null

  it 'should return required actions for syncing quantity', ->
    inventoryChanged = _.deepClone @inventory
    inventoryChanged.quantityOnStock = 10

    delta = @utils.diff(@inventory, inventoryChanged)
    update = @utils.actionsMapQuantity(delta, inventoryChanged)

    expected_update =
      [
        { action: 'addQuantity', quantity: 3 }
      ]
    expect(update).toEqual expected_update
