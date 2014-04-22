_ = require 'underscore'
OrderSync = require '../../lib/sync/order-sync'
Config = require('../../config').config.prod

OLD_ORDER =
  id: '123'
  orderState: 'Open'
  paymentState: 'Pending'
  shipmentState: 'Pending'
  version: 2

NEW_ORDER =
  id: '123'
  orderState: 'Complete'
  paymentState: 'Paid'
  shipmentState: 'Ready'
  version: 1

describe 'OrderSync', ->

  it 'should initialize', ->
    sync = new OrderSync
    expect(sync).toBeDefined()
    expect(sync._actions).not.toBeDefined()

  it 'should initialize with options', ->
    sync = new OrderSync
      config: Config
      logConfig:
        levelStream: 'error'
        levelFile: 'error'
    expect(sync).toBeDefined()
    expect(sync._client).toBeDefined()
    expect(sync._client._rest._options.config).toEqual Config

  it 'should throw error if no credentials are given', ->
    sync = -> new OrderSync foo: 'bar'
    expect(sync).toThrow new Error('Missing credentials')

  _.each ['client_id', 'client_secret', 'project_key'], (key) ->
    it "should throw error if no '#{key}' is defined", ->
      opt = _.clone(Config)
      delete opt[key]
      sync = -> new OrderSync
        config: opt
        logConfig:
          levelStream: 'error'
          levelFile: 'error'
      expect(sync).toThrow new Error("Missing '#{key}'")

  describe ':: config', ->

    beforeEach ->
      @sync = new OrderSync

    afterEach ->
      @sync = null

    it 'should build white/black-listed actions update', ->
      opts = [
        {type: 'status', group: 'white'}
        {type: 'returnInfo', group: 'black'}
      ]
      spyOn(@sync._utils, 'actionsMapReturnInfo').andReturn [{action: 'addReturnInfo', returnTrackingId: '1234', items: []}]
      update = @sync.config(opts).buildActions(NEW_ORDER, OLD_ORDER).get()
      expected_update =
        actions: [
          { action: 'changeOrderState', orderState: 'Complete' }
          { action: 'changePaymentState', paymentState: 'Paid' }
          { action: 'changeShipmentState', shipmentState: 'Ready' }
        ]
        version: OLD_ORDER.version
      expect(update).toEqual expected_update

  describe ':: buildActions', ->

    beforeEach ->
      @sync = new OrderSync

    afterEach ->
      @sync = null

    it 'should build the action update', ->
      update = @sync.buildActions(NEW_ORDER, OLD_ORDER).get()
      expected_update =
        actions: [
          { action: 'changeOrderState', orderState: 'Complete' }
          { action: 'changePaymentState', paymentState: 'Paid' }
          { action: 'changeShipmentState', shipmentState: 'Ready' }
        ]
        version: OLD_ORDER.version
      expect(update).toEqual expected_update


  describe ':: update', ->

    beforeEach ->
      @sync = new OrderSync
        config: Config
        logConfig:
          levelStream: 'error'
          levelFile: 'error'

    afterEach ->
      @sync = null

    it 'should send update request', (done) ->
      spyOn(@sync._client._rest, 'POST').andCallFake((path, payload, callback) -> callback(null, {statusCode: 200}, {id: '123'}))
      @sync._data =
        update:
          actions: []
          version: 1
        updateId: '123'
      @sync.update()
      .then (result) =>
        expect(result.statusCode).toBe 200
        expect(result.body.id).toBe '123'
        expect(@sync._client._rest.POST).toHaveBeenCalledWith('/orders/123', @sync._data.update, jasmine.any(Function))
        done()
      .fail (error) -> done(error)