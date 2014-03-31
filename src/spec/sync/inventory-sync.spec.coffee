_ = require 'underscore'
InventorySync = require '../../lib/sync/inventory-sync'
Config = require('../../config').config.prod

describe 'InventorySync', ->

  it 'should initialize', ->
    sync = new InventorySync
    expect(sync).toBeDefined()
    expect(sync._actions).not.toBeDefined()

  it 'should initialize with options', ->
    sync = new InventorySync
      config: Config
      logConfig:
        levelStream: 'error'
        levelFile: 'error'
    expect(sync).toBeDefined()
    expect(sync._rest).toBeDefined()
    expect(sync._rest._options.config).toEqual Config

  it 'should throw error if no credentials are given', ->
    sync = -> new InventorySync foo: 'bar'
    expect(sync).toThrow new Error('Missing credentials')

  _.each ['client_id', 'client_secret', 'project_key'], (key) ->
    it "should throw error if no '#{key}' is defined", ->
      opt = _.clone(Config)
      delete opt[key]
      sync = -> new InventorySync
        config: opt
        logConfig:
          levelStream: 'error'
          levelFile: 'error'
      expect(sync).toThrow new Error("Missing '#{key}'")

describe 'InventorySync.config', ->

  beforeEach ->
    @sync = new InventorySync

  afterEach ->
    @sync = null

  it 'should build white/black-listed actions update', ->
    opts = [
      {type: 'quantity', group: 'white'}
      {type: 'expectedDelivery', group: 'black'}
    ]
    newInventory =
      id: '123'
      quantityOnStock: 2
      version: 1
    oldInventory =
      id: '123'
      quantityOnStock: 10
      version: 1
    spyOn(@sync._utils, 'actionsMapExpectedDelivery').andReturn [{action: 'setExpectedDelivery', expectedDelivery: "2001-09-11T14:00:00.000Z"}]
    update = @sync.config(opts).buildActions(newInventory, oldInventory).get()
    expected_update =
      actions: [
        { action: 'removeQuantity', quantity: 8 }
      ]
      version: oldInventory.version
    expect(update).toEqual expected_update

describe '#buildActions', ->

  beforeEach ->
    @sync = new InventorySync

  it 'no differences', ->
    ie =
      id: 'abc'
      sku: '123'
      quantityOnStock: 7
    update = @sync.buildActions(ie, ie).get()
    expect(update).toBeUndefined()
    updateId = @sync.buildActions(ie, ie).get('updateId')
    expect(updateId).toBe 'abc'

  it 'more quantity', ->
    ieNew =
      sku: '123'
      quantityOnStock: 77
    ieOld =
      sku: '123'
      quantityOnStock: 9
    update = @sync.buildActions(ieNew, ieOld).get()
    expect(update).toBeDefined()
    expect(update.actions[0].action).toBe 'addQuantity'
    expect(update.actions[0].quantity).toBe 68

  it 'less quantity', ->
    ieNew =
      sku: '123'
      quantityOnStock: 7
    ieOld =
      sku: '123'
      quantityOnStock: 9
    update = @sync.buildActions(ieNew, ieOld).get()
    expect(update).toBeDefined()
    expect(update.actions[0].action).toBe 'removeQuantity'
    expect(update.actions[0].quantity).toBe 2

  it 'should add expectedDelivery', ->
    ieNew =
      sku: 'xyz'
      quantityOnStock: 9
      expectedDelivery: '2014-01-01T01:02:03'
    ieOld =
      sku: 'xyz'
      quantityOnStock: 9
    update = @sync.buildActions(ieNew, ieOld).get()
    expect(update).toBeDefined()
    expect(update.actions[0].action).toBe 'setExpectedDelivery'
    expect(update.actions[0].expectedDelivery).toBe '2014-01-01T01:02:03'

  it 'should update expectedDelivery', ->
    ieNew =
      sku: 'abc'
      quantityOnStock: 0
      expectedDelivery: '2000'
    ieOld =
      sku: 'abc'
      quantityOnStock: 0
      expectedDelivery: '1999'
    update = @sync.buildActions(ieNew, ieOld).get()
    expect(update).toBeDefined()
    expect(update.actions[0].action).toBe 'setExpectedDelivery'
    expect(update.actions[0].expectedDelivery).toBe '2000'

  it 'should remove expectedDelivery', ->
    ieNew =
      sku: 'abc'
      quantityOnStock: 0
    ieOld =
      sku: 'abc'
      quantityOnStock: 0
      expectedDelivery: '1999'
    update = @sync.buildActions(ieNew, ieOld).get()
    expect(update).toBeDefined()
    expect(update.actions[0].action).toBe 'setExpectedDelivery'
    expect(update.actions[0].expectedDelivery).toBeUndefined()


describe '#update', ->

  beforeEach ->
    @sync = new InventorySync
      config: Config
      logConfig:
        levelStream: 'error'
        levelFile: 'error'

  it 'should send update request', (done) ->
    spyOn(@sync._rest, 'POST').andCallFake((path, payload, callback) -> callback(null, null, {id: '123'}))
    @sync._data =
      update:
        actions: [ { name: 'addQuantity', quantity: 7 } ]
        version: 1
      updateId: '123'
    callMe = (e, r, b) ->
      expect(b.id).toBe '123'
      done()
    @sync.update(callMe)
    expect(@sync._rest.POST).toHaveBeenCalledWith('/inventory/123', JSON.stringify(@sync._data.update), jasmine.any(Function))
