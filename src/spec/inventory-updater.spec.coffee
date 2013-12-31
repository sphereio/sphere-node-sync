_ = require("underscore")._
InventoryUpdater = require("../main").InventoryUpdater
Config = require("../config").config.prod

describe "InventoryUpdater", ->

  it "should initialize", ->
    updater = new InventoryUpdater
    expect(updater).toBeDefined()

  it "should initialize with options", ->
    updater = new InventoryUpdater config: Config
    expect(updater).toBeDefined()

  xit "should throw error if no credentials are given", ->
    updater = -> new InventoryUpdater foo: "bar"
    expect(updater).toThrow new Error("Missing credentials")

describe "#createEntry", ->
  beforeEach ->
    @updater = new InventoryUpdater

  it "should create simplest entry", ->
    e = @updater.createInventoryEntry('123', 3)
    expect(e.sku).toBe '123'
    expect(e.quantityOnStock).toBe 3
    expect(e.supplyChannel).toBeUndefined
    expect(e.expectedDelivery).toBeUndefined

  it "should create complex entry", ->
    e = @updater.createInventoryEntry('abc', -7, '1970-01-01T11:11:11Z000', 'channel123')
    expect(e.sku).toBe 'abc'
    expect(e.quantityOnStock).toBe -7
    expect(e.expectedDelivery).toBe '1970-01-01T11:11:11Z000'
    expect(e.supplyChannel.typeId).toBe 'channel'
    expect(e.supplyChannel.id).toBe 'channel123'

describe '#ensureChannelByKey', ->
  beforeEach ->
    @updater = new InventoryUpdater config: Config

  it 'should query for channel by key', (done) ->
    spyOn(@updater.rest, "GET").andCallFake((path, callback) ->
      callback(null, {statusCode: 200}, '{ "results": [{ "id": "channel123" }] }'))

    @updater.ensureChannelByKey(@updater.rest, 'bar').then (channel) =>
      uri = '/channels?where=key%3D%22bar%22'
      expect(@updater.rest.GET).toHaveBeenCalledWith(uri, jasmine.any(Function))
      expect(channel.id).toBe 'channel123'
      done()
    .fail (msg) ->
      expect(true).toBe false
      done()