_ = require("underscore")._
InventorySync = require("../lib/inventory-sync")
Config = require('../config').config
order = require("../models/order.json")
Rest = require("sphere-node-connect").Rest
Q = require('q')

# Increase timeout
jasmine.getEnv().defaultTimeoutInterval = 10000

describe "Integration test", ->

  beforeEach (done) ->
    @sync = new InventorySync config: Config.staging
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
      stocks = JSON.parse(body).results
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

  it "should update order", (done) ->
    ie =
      sku: '123'
      quantityOnStock: 3
    ieChanged =
      sku: '123'
      quantityOnStock: 7
    @sync._rest.POST "/inventory", JSON.stringify(ie), (error, response, body) =>
      expect(error).toBeNull()
      expect(response.statusCode).toBe 201
      e = JSON.parse(body)
      @sync.buildActions(ieChanged, e).update (error, response, body) ->
        expect(error).toBeNull()
        expect(response.statusCode).toBe 200
        expect(JSON.parse(body).quantityOnStock).toBe 7
        done()
