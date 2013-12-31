_ = require("underscore")._
OrderSync = require("../lib/order-sync")
Config = require('../config').config
order = require("../models/order.json")
Rest = require("sphere-node-connect").Rest

# Increase timeout
jasmine.getEnv().defaultTimeoutInterval = 10000

xdescribe "Integration test", ->
  ORDER_ID = "455e92b4-2a75-4cb8-bfdd-eb78c7f227cb"
  VERSION_ID = 1

  beforeEach ->
    @sync = new OrderSync config: Config.staging

  afterEach ->
    @sync = null

  it "should get orders", (done)->
    @sync._rest.GET "/orders/#{ORDER_ID}", (error, response, body)->
      expect(response.statusCode).toBe 200
      json = JSON.parse(body)
      expect(json).toBeDefined()
      expect(json.id).toBe ORDER_ID
      VERSION_ID = json.version # we save the version for the udpate later (dirty, I know!)
      done()

  it "should return 404 if order is not found", (done)->
    @sync._rest.GET "/orders/123", (error, response, body)->
      expect(response.statusCode).toBe 404
      done()

  it "should update an order", (done)->
    timestamp = new Date().getTime()
    NEW_ORDER =
      orderState: "Complete"
      paymentState: "Paid"
      shipmentState: "Ready"
    # let's reset the statues first, so that the sync will work
    payload = JSON.stringify
      actions: [
        { action: "changeOrderState", orderState: "Open" }
        { action: "changePaymentState", paymentState: "Pending" }
        { action: "changeShipmentState", shipmentState: "Pending" }
      ]
      version: VERSION_ID
    @sync._rest.POST "/orders/#{ORDER_ID}", payload, (error, response, body)=>
      if response.statusCode is 200
        old_order = JSON.parse(body)
        @sync.buildActions(NEW_ORDER, old_order).update (e, r, b)->
          expect(r.statusCode).toBe 200
          console.error b unless r.statusCode is 200
          updated = JSON.parse(b)
          expect(updated).toBeDefined()
          expect(updated.orderState).toBe "Complete"
          expect(updated.paymentState).toBe "Paid"
          expect(updated.shipmentState).toBe "Ready"
          done()
      else
        console.error body
        throw new Error "Could not update order"
