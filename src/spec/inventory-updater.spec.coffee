_ = require("underscore")._
Q = require('q')
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

  it 'should return a promise', ->
    promise = @updater.ensureChannelByKey(@updater.rest, 'foo')
    expect(Q.isPromise(promise)).toBe true

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

describe '#allInventoryEntries', ->
  beforeEach ->
    @updater = new InventoryUpdater config: Config

  it 'should return a promise', ->
    promise = @updater.allInventoryEntries(@updater.rest)
    expect(Q.isPromise(promise)).toBe true

  it 'should query all entries', ->
    spyOn(@updater.rest, "GET").andCallFake((path, callback) ->
      callback(null, {statusCode: 200}, '{ "results": [{ "id": "channel123" }] }'))

    @updater.allInventoryEntries(@updater.rest).then (stocks) =>
      expect(stocks.length).toBe 1
      done()

  it 'should reject if status code is not 200', ->
    spyOn(@updater.rest, "GET").andCallFake((path, callback) ->
      callback(null, {statusCode: 400}, "foo"))

    @updater.allInventoryEntries(@updater.rest).then (stocks) =>
      expect(stocks).not.toBeDefined()
      done()
    .fail (msg)->
      expect(msg).toBe 'Problem on getting all inventory entries: foo'
      done()

  it 'should reject if error', ->
    spyOn(@updater.rest, "GET").andCallFake((path, callback) ->
      callback("foo", null, null))

    @updater.allInventoryEntries(@updater.rest).then (stocks) =>
      expect(stocks).not.toBeDefined()
      done()
    .fail (msg)->
      expect(msg).toBe 'Error on getting all inventory entries: foo'
      done()

describe '#initMatcher', ->
  beforeEach ->
    @updater = new InventoryUpdater config: Config

  it 'should return a promise', ->
    promise = @updater.initMatcher()
    expect(Q.isPromise(promise)).toBe true

  it 'should reject if error', ->
    spyOn(@updater.rest, "GET").andCallFake((path, callback) ->
      callback("foo", null, null))

    @updater.initMatcher().then (entries) =>
      expect(entries).not.toBeDefined()
      done()
    .fail (msg)->
      expect(msg).toBe 'Error on getting all inventory entries: foo'
      done()

  it 'should return existing entries', ->
    spyOn(@updater.rest, "GET").andCallFake((path, callback) ->
      callback(null, {statusCode: 200}, '{ "results": [{ "id": "channel123", "sku": "foo" }] }'))

    @updater.initMatcher().then (result) =>
      expect(@updater.existingInventoryEntries).toEqual [{ id: "channel123", sku: "foo" }]
      expect(@updater.sku2index.foo).toBe 0
      expect(result).toBe true
      done()

describe '#match', ->
  beforeEach ->
    @updater = new InventoryUpdater config: Config
    @updater.existingInventoryEntries = [{ id: "channel123", sku: "foo" }]
    @updater.sku2index = foo: 0

  it 'should return entry based on sku', ->
    entry = @updater.match sku: "foo"
    expect(entry).toEqual { id: "channel123", sku: "foo" }

describe '#update', ->
  beforeEach ->
    @updater = new InventoryUpdater config: Config

  it 'should return a promise', ->
    spyOn(@updater.sync, "buildActions").andReturn(@updater.sync)
    spyOn(@updater.sync, "update")
    promise = @updater.update()
    expect(Q.isPromise(promise)).toBe true
    expect(@updater.sync.buildActions).toHaveBeenCalled()
    expect(@updater.sync.update).toHaveBeenCalled()

  it 'should reject if error', ->
    spyOn(@updater.sync, "buildActions").andReturn(@updater.sync)
    spyOn(@updater.sync, "update").andCallFake((callback)-> callback("foo", null, null))

    @updater.update().then (result) =>
      expect(result).not.toBeDefined()
      done()
    .fail (msg)->
      expect(msg).toBe 'Error on updating inventory entry: foo'
      done()

  it 'should reject if there was a problem during update', ->
    spyOn(@updater.sync, "buildActions").andReturn(@updater.sync)
    spyOn(@updater.sync, "update").andCallFake((callback)-> callback(null, {statusCode: 500}, "foo"))

    @updater.update().then (result) =>
      expect(result).not.toBeDefined()
      done()
    .fail (msg)->
      expect(msg).toBe 'Problem on updating existing inventory entry: foo'
      done()

  it 'should return message that entry was updated', ->
    spyOn(@updater.sync, "buildActions").andReturn(@updater.sync)
    spyOn(@updater.sync, "update").andCallFake((callback)-> callback(null, {statusCode: 200}, null))

    @updater.update().then (result) =>
      expect(result).toBe 'Inventory entry updated.'
      done()

  it 'should return message that updated was not necessary', ->
    spyOn(@updater.sync, "buildActions").andReturn(@updater.sync)
    spyOn(@updater.sync, "update").andCallFake((callback)-> callback(null, {statusCode: 304}, null))

    @updater.update().then (result) =>
      expect(result).toBe 'Inventory entry update not neccessary.'
      done()

describe '#create', ->
  beforeEach ->
    @updater = new InventoryUpdater config: Config

  it 'should return a promise', ->
    spyOn(@updater.rest, "POST")
    promise = @updater.create()
    expect(Q.isPromise(promise)).toBe true
    expect(@updater.rest.POST).toHaveBeenCalled()

  it 'should reject if error', ->
    spyOn(@updater.rest, "POST").andCallFake((path, payload, callback)-> callback("foo", null, null))

    @updater.create().then (result) =>
      expect(result).not.toBeDefined()
      done()
    .fail (msg)->
      expect(msg).toBe 'Error on creating new inventory entry: foo'
      done()

  it 'should reject if there was a problem during create', ->
    spyOn(@updater.rest, "POST").andCallFake((path, payload, callback)-> callback(null, {statusCode: 500}, "foo"))

    @updater.create().then (result) =>
      expect(result).not.toBeDefined()
      done()
    .fail (msg)->
      expect(msg).toBe 'Problem on creating new inventory entry: foo'
      done()

  it 'should return message that entry was created', ->
    spyOn(@updater.rest, "POST").andCallFake((path, payload, callback)-> callback(null, {statusCode: 201}, null))

    @updater.create().then (result) =>
      expect(result).toBe 'New inventory entry created.'
      done()
