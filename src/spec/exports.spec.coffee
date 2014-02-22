{ProductSync, OrderSync, InventorySync, InventoryUpdater, CommonUpdater} = require '../lib/main'

describe 'exports', ->

  it 'ProductSync', ->
    expect(ProductSync).toBeDefined()

  it 'OrderSync', ->
    expect(OrderSync).toBeDefined()

  it 'InventorySync', ->
    expect(InventorySync).toBeDefined()

  it 'InventoryUpdater', ->
    expect(InventoryUpdater).toBeDefined()

  it 'CommonUpdater', ->
    expect(CommonUpdater).toBeDefined()
