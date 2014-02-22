_ = require('underscore')._
Q = require 'q'
{Rest} = require 'sphere-node-connect'
InventorySync = require '../../lib/sync/inventory-sync'
Config = require('../../config').config
order = require '../../models/order.json'

# Increase timeout
jasmine.getEnv().defaultTimeoutInterval = 10000

describe 'Integration test', ->

  beforeEach (done) ->
    @sync = new InventorySync
      config: Config.staging
      logConfig:
        levelStream: 'error'
        levelFile: 'error'
    del = (id) =>
      deferred = Q.defer()
      @sync._rest.DELETE "/inventory/#{id}", (error, response, body) ->
        if error
          deferred.reject error
        else
          if response.statusCode is 200 or statusCode is 404
            deferred.resolve true
          else
            deferred.reject body
      deferred.promise

    @sync._rest.GET "/inventory?limit=0", (error, response, body) ->
      stocks = body.results
      if stocks.length is 0
        done()
      dels = []
      for s in stocks
        dels.push del(s.id)

      Q.all(dels).then (v) ->
        done()
      .fail (err) ->
        console.log err
        expect(false).toBe true

  it 'should update inventory entry', (done) ->
    ie =
      sku: '123'
      quantityOnStock: 3
    ieChanged =
      sku: '123'
      quantityOnStock: 7
    @sync._rest.POST '/inventory', JSON.stringify(ie), (error, response, body) =>
      expect(error).toBeNull()
      expect(response.statusCode).toBe 201
      @sync.buildActions(ieChanged, body).update (error, response, body) ->
        expect(error).toBeNull()
        expect(response.statusCode).toBe 200
        expect(body.quantityOnStock).toBe 7
        done()

  it 'should add expectedDelivery date', (done) ->
    ie =
      sku: 'x1'
      quantityOnStock: 3
    ieChanged =
      sku: 'x1'
      quantityOnStock: 7
      expectedDelivery: '2000-01-01T01:01:01'
    @sync._rest.POST '/inventory', JSON.stringify(ie), (error, response, body) =>
      expect(error).toBeNull()
      expect(response.statusCode).toBe 201
      @sync.buildActions(ieChanged, body).update (error, response, body) ->
        expect(error).toBeNull()
        expect(response.statusCode).toBe 200
        expect(body.quantityOnStock).toBe 7
        expect(body.expectedDelivery).toBe '2000-01-01T01:01:01.000Z'
        done()

  it 'should update expectedDelivery date', (done) ->
    ie =
      sku: 'x2'
      quantityOnStock: 3
      expectedDelivery: '1999-01-01T01:01:01.000Z'
    ieChanged =
      sku: 'x2'
      quantityOnStock: 3
      expectedDelivery: '2000-01-01T01:01:01.000Z'
    @sync._rest.POST '/inventory', JSON.stringify(ie), (error, response, body) =>
      expect(error).toBeNull()
      expect(response.statusCode).toBe 201
      @sync.buildActions(ieChanged, body).update (error, response, body) ->
        expect(error).toBeNull()
        expect(response.statusCode).toBe 200
        expect(body.quantityOnStock).toBe 3
        expect(body.expectedDelivery).toBe '2000-01-01T01:01:01.000Z'
        done()

  it 'should remove expectedDelivery date', (done) ->
    ie =
      sku: 'x3'
      quantityOnStock: 3
      expectedDelivery: '2000-01-01T01:01:01.000Z'
    ieChanged =
      sku: 'x3'
      quantityOnStock: 3
    @sync._rest.POST '/inventory', JSON.stringify(ie), (error, response, body) =>
      expect(error).toBeNull()
      expect(response.statusCode).toBe 201
      @sync.buildActions(ieChanged, body).update (error, response, body) ->
        expect(error).toBeNull()
        expect(response.statusCode).toBe 200
        expect(body.quantityOnStock).toBe 3
        expect(body.expectedDelivery).toBeUndefined()
        done()
