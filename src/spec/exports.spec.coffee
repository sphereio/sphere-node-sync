ProductSync = require('../main.js').ProductSync
OrderSync = require('../main.js').OrderSync
InventorySync = require('../main.js').InventorySync

describe "exports", ->
  it "ProductSync", ->
    expect(ProductSync).toBeDefined()

  it "OrderSync", ->
    expect(OrderSync).toBeDefined()

  it "InventorySync", ->
    expect(InventorySync).toBeDefined()