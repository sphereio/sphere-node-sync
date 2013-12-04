_ = require("underscore")._
InventorySync = require("../lib/inventory-sync")
Config = require("../config").config.prod

describe "InventorySync", ->

  it "should initialize", ->
    sync = new InventorySync
    expect(sync).toBeDefined()
    expect(sync._actions).not.toBeDefined()

  it "should initialize with options", ->
    sync = new InventorySync config: Config
    expect(sync).toBeDefined()
    expect(sync._rest).toBeDefined()
    expect(sync._rest._options.config).toEqual Config

  it "should throw error if no credentials are given", ->
    sync = -> new InventorySync foo: "bar"
    expect(sync).toThrow new Error("Missing credentials")

  _.each ["client_id", "client_secret", "project_key"], (key)->
    it "should throw error if no '#{key}' is defined", ->
      opt = _.clone(Config)
      delete opt[key]
      sync = -> new InventorySync config: opt
      expect(sync).toThrow new Error("Missing '#{key}'")

describe "#buildActions", ->

  beforeEach ->
    @sync = new InventorySync

  it "no differences", ->
    ie =
      id: "abc"
      sku: "123"
      quantity: 7
    update = @sync.buildActions(ie, ie).get()
    expect(update).toBeUndefined()
    updateId = @sync.buildActions(ie, ie).get("updateId")
    expect(updateId).toBe "abc"

  it "more quantity", ->
    ieNew =
      sku: "123"
      quantity: 77
    ieOld =
      sku: "123"
      quantity: 9
    update = @sync.buildActions(ieNew, ieOld).get()
    expect(update).toBeDefined()
    expect(update.actions[0].action).toBe 'addQuantity'
    expect(update.actions[0].quantity).toBe 68

  it "less quantity", ->
    ieNew =
      sku: "123"
      quantity: 7
    ieOld =
      sku: "123"
      quantity: 9
    update = @sync.buildActions(ieNew, ieOld).get()
    expect(update).toBeDefined()
    expect(update.actions[0].action).toBe 'removeQuantity'
    expect(update.actions[0].quantity).toBe 2