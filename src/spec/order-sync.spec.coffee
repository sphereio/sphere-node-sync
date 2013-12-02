_ = require("underscore")._
OrderSync = require("../lib/order-sync")
Config = require("../config").config.prod

OLD_ORDER =
  id: "123"
  orderState: "Open"
  paymentState: "Pending"
  shipmentState: "Pending"
  version: 2

NEW_ORDER =
  id: "123"
  orderState: "Complete"
  paymentState: "Paid"
  shipmentState: "Ready"
  version: 1

describe "OrderSync", ->

  it "should initialize", ->
    sync = new OrderSync
    expect(sync).toBeDefined()
    expect(sync._actions).not.toBeDefined()

  it "should initialize with options", ->
    sync = new OrderSync config: Config
    expect(sync).toBeDefined()
    expect(sync._rest).toBeDefined()
    expect(sync._rest._options.config).toEqual Config

  it "should throw error if no credentials are given", ->
    sync = -> new OrderSync foo: "bar"
    expect(sync).toThrow new Error("Missing credentials")

  _.each ["client_id", "client_secret", "project_key"], (key)->
    it "should throw error if no '#{key}' is defined", ->
      opt = _.clone(Config)
      delete opt[key]
      sync = -> new OrderSync config: opt
      expect(sync).toThrow new Error("Missing '#{key}'")


describe "OrderSync.buildActions", ->

  beforeEach ->
    @sync = new OrderSync

  afterEach ->
    @sync = null

  it "should build the action update", ->
    update = @sync.buildActions(NEW_ORDER, OLD_ORDER).get()
    expected_update =
      actions: [
        { action: "changeOrderState", orderState: "Complete" }
        { action: "changePaymentState", paymentState: "Paid" }
        { action: "changeShipmentState", shipmentState: "Ready" }
      ]
      version: OLD_ORDER.version
    expect(update).toEqual expected_update


describe "OrderSync.update", ->

  beforeEach ->
    @sync = new OrderSync config: Config

  afterEach ->
    @sync = null

  it "should send update request", (done)->
    spyOn(@sync._rest, "POST").andCallFake((path, payload, callback)-> callback(null, null, {id: "123"}))
    @sync._data =
      update:
        actions: []
        version: 1
      updateId: "123"
    callMe = (e, r, b)->
      expect(b.id).toBe "123"
      done()
    @sync.update(callMe)
    expect(@sync._rest.POST).toHaveBeenCalledWith("/orders/123", JSON.stringify(@sync._data.update), jasmine.any(Function))
