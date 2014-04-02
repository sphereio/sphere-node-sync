{ProductSync, OrderSync, InventorySync} = require '../lib/main'

describe 'exports', ->

  it 'ProductSync', ->
    expect(ProductSync).toBeDefined()

  it 'OrderSync', ->
    expect(OrderSync).toBeDefined()

  it 'InventorySync', ->
    expect(InventorySync).toBeDefined()
