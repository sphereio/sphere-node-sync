ProductSync = require('../lib/main').ProductSync
OrderSync = require('../lib/main').OrderSync
InventorySync = require('../lib/main').InventorySync
InventoryUpdater = require('../lib/main').InventoryUpdater
CommonUpdater = require('../lib/main').CommonUpdater

describe "exports", ->
  it "ProductSync", ->
    expect(ProductSync).toBeDefined()

  it "OrderSync", ->
    expect(OrderSync).toBeDefined()

  it "InventorySync", ->
    expect(InventorySync).toBeDefined()

  it "InventoryUpdater", ->
    expect(InventoryUpdater).toBeDefined()

  it "CommonUpdater", ->
    expect(CommonUpdater).toBeDefined()
