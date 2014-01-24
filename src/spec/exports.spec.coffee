ProductSync = require('../lib/sync/product-sync')
OrderSync = require('../lib/sync/order-sync')
InventorySync = require('../lib/sync/inventory-sync')

describe "exports", ->
  it "ProductSync", ->
    expect(ProductSync).toBeDefined()

  it "OrderSync", ->
    expect(OrderSync).toBeDefined()

  it "InventorySync", ->
    expect(InventorySync).toBeDefined()