ProductSync = require('../lib/sync/product-sync')
OrderSync = require('../lib/sync/order-sync')
InventorySync = require('../lib/sync/inventory-sync')
InventoryUpdater = require('../lib/updater/inventory-updater')

describe "exports", ->
  it "ProductSync", ->
    expect(ProductSync).toBeDefined()

  it "OrderSync", ->
    expect(OrderSync).toBeDefined()

  it "InventorySync", ->
    expect(InventorySync).toBeDefined()

  it "InventoryUpdater", ->
    expect(InventoryUpdater).toBeDefined()
