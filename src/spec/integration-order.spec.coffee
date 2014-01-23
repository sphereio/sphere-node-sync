_ = require("underscore")._
Q = require('q')
OrderSync = require("../lib/order-sync")
Config = require('../config').config
order = require("../models/order.json")
Rest = require("sphere-node-connect").Rest

# Increase timeout
jasmine.getEnv().defaultTimeoutInterval = 10000

productTypeMock = () ->
  unique = new Date().getTime()
  productType =
    name: "PT-#{unique}"
    description: 'bla'

productMock = (productType) ->
  unique = new Date().getTime()
  product =
    productType:
      typeId: 'product-type'
      id: productType.id
    name:
      en: "P-#{unique}"
    slug:
      en: "p-#{unique}"
    masterVariant:
      sku: "sku-#{unique}"

orderMock = (product) ->
  unique = new Date().getTime()
  order =
    id: "order-#{unique}"
    orderState: 'Complete'
    lineItems: [ {
      productId: product.id
      name:
        de: 'foo'
      variant:
        id: 1
      taxRate:
        name: 'myTax'
        amount: 0.10
        includedInPrice: false
        country: 'DE'
      quantity: 1
      price:
        value:
          centAmount: 999
          currencyCode: 'EUR'
    } ]
    totalPrice:
      currencyCode: 'EUR'
      centAmount: 999

createResourcePromise = (rest, url, body) ->
  deferred = Q.defer()
  rest.POST url, JSON.stringify(body), (error, response, body) ->
    if response.statusCode is 201
      deferred.resolve JSON.parse(body)
    else if error
      console.log error
      deferred.reject new Error(error)
    else
      console.log body
      deferred.reject new Error(body)
  deferred.promise

deleteResourcePromise = (rest, url) ->
  deferred = Q.defer()
  rest.DELETE url, (error, response, body) =>
    if response.statusCode is 200
      deferred.resolve JSON.parse(body)
    else if error
      console.log error
      deferred.reject new Error(error)
    else
      console.log body
      deferred.reject new Error(body)
  deferred.promise

describe "OrderSync Integration", ->

  beforeEach (done) ->
    @sync = new OrderSync config: Config.staging

    createResourcePromise(@sync._rest, '/product-types', productTypeMock())
      .then (productType) =>
        @productType = productType
        createResourcePromise(@sync._rest, '/products', productMock(productType))
    .then (product) =>
      @product = product
      createResourcePromise(@sync._rest, '/orders/import', orderMock(product))
    .then (order) =>
      @order = order
      done()

  afterEach (done) ->

    # TODO: delete order (not supported by API yet)
    deleteResourcePromise(@sync._rest, "/products/#{@product.id}?version=#{@product.version}")
      .then (product) =>
        deleteResourcePromise(@sync._rest, "/product-types/#{@productType.id}?version=#{@productType.version}")
    .then (productType) =>
      done()

  it "should do nothing", (done) ->
    expect(true).toBe true
    done()


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
