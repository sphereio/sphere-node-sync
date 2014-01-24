_ = require("underscore")._
Q = require('q')
OrderSync = require("../lib/order-sync")
Config = require('../config').config
order = require("../models/order.json")
Rest = require("sphere-node-connect").Rest

# Increase timeout
jasmine.getEnv().defaultTimeoutInterval = 10000

describe "Integration test", ->

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
    .fail (error) ->
      done(error)

  afterEach (done) ->

    # TODO: delete order (not supported by API yet)
    deleteResourcePromise(@sync._rest, "/products/#{@product.id}?version=#{@product.version}")
      .then (product) =>
        deleteResourcePromise(@sync._rest, "/product-types/#{@productType.id}?version=#{@productType.version}")
    .then (productType) =>
      done()
    .fail (error) ->
      done(error)
    .fin ->
      @product = null
      @productType = null
      @order = null

  it "should update an order", (done)->
    orderNew =
      orderState: "Complete"
      paymentState: "Paid"
      shipmentState: "Ready"

    @sync.buildActions(orderNew, @order).update (error, response, body)->
      expect(response.statusCode).toBe 200
      console.error body unless response.statusCode is 200
      orderUpdated = JSON.parse(body)
      expect(orderUpdated).toBeDefined()
      expect(orderUpdated.orderState).toBe orderNew.orderState
      expect(orderUpdated.paymentState).toBe orderNew.paymentState
      expect(orderUpdated.shipmentState).toBe orderNew.shipmentState
      done()

###
helper methods
###

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
    orderState: 'Open'
    paymentState: 'Pending'
    shipmentState: 'Pending'

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
      deferred.reject new Error(error)
    else
      deferred.reject new Error(body)
  deferred.promise

deleteResourcePromise = (rest, url) ->
  deferred = Q.defer()
  rest.DELETE url, (error, response, body) =>
    if response.statusCode is 200
      deferred.resolve JSON.parse(body)
    else if error
      deferred.reject new Error(error)
    else
      deferred.reject new Error(body)
  deferred.promise