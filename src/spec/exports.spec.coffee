ProductSync = require('../lib/product-sync')
OrderSync = require('../lib/order-sync')
InventorySync = require('../lib/inventory-sync')

describe "exports", ->
  it "ProductSync", ->
    expect(ProductSync).toBeDefined()

  it "OrderSync", ->
    expect(OrderSync).toBeDefined()

  it "InventorySync", ->
    expect(InventorySync).toBeDefined()