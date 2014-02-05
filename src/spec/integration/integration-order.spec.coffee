_ = require("underscore")._
Q = require('q')
Rest = require("sphere-node-connect").Rest
OrderSync = require("../../lib/sync/order-sync")
Config = require('../../config').config
order = require("../../models/order.json")

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
    .then (productType) ->
      done()
    .fail (error) ->
      done(error)
    .fin ->
      @product = null
      @productType = null
      @order = null

  it "should update an order", (done)->

    orderNew = JSON.parse(JSON.stringify(@order))
    orderNew.orderState = "Complete"
    orderNew.paymentState = "Paid"
    orderNew.shipmentState = "Ready"

    @sync.buildActions(orderNew, @order).update (error, response, body)->
      expect(response.statusCode).toBe 200
      console.error body unless response.statusCode is 200
      orderUpdated = JSON.parse(body)
      expect(orderUpdated).toBeDefined()
      expect(orderUpdated.orderState).toBe orderNew.orderState
      expect(orderUpdated.paymentState).toBe orderNew.paymentState
      expect(orderUpdated.shipmentState).toBe orderNew.shipmentState
      done()

  it "should sync returnInfo", (done) ->

    orderNew = JSON.parse(JSON.stringify(@order))

    orderNew.returnInfo.push
      returnTrackingId: "1"
      returnDate: new Date()
      items: [{
        quantity: 1
        lineItemId: @order.lineItems[0].id
        comment: 'Product doesnt have enough mojo.'
        shipmentState: 'Advised'
      }]

    @sync.buildActions(orderNew, @order).update (error, response, body) ->
      expect(response.statusCode).toBe 200
      console.error body unless response.statusCode is 200
      orderUpdated = JSON.parse(body)

      expect(orderUpdated).toBeDefined()
      expect(orderUpdated.returnInfo[0].id).toBe orderNew.returnInfo[0].id

      done()

  it "should sync returnInfo status", (done) ->

    orderNew = JSON.parse(JSON.stringify(@order))

    orderNew.returnInfo.push
      returnTrackingId: "bla blubb"
      returnDate: new Date()
      items: [{
        quantity: 1
        lineItemId: @order.lineItems[0].id
        comment: 'Product doesnt have enough mojo.'
        shipmentState: 'Returned'
      }]

    # prepare order: add returnInfo first
    @sync.buildActions(orderNew, @order).update (error, response, body) =>

      console.error body unless response.statusCode is 200
      orderUpdated = JSON.parse(body)

      orderNew2 = JSON.parse(JSON.stringify(orderUpdated))

      orderNew2.returnInfo[0].items[0].shipmentState = 'BackInStock'
      orderNew2.returnInfo[0].items[0].paymentState = 'Refunded'

      # update returnInfo status
      @sync.buildActions(orderNew2, orderUpdated).update (error, response, body) =>
        
        expect(response.statusCode).toBe 200
        console.error body unless response.statusCode is 200
        orderUpdated2 = JSON.parse(body)

        expect(orderUpdated2).toBeDefined()
        expect(orderUpdated2.returnInfo[0].items[0].shipmentState).toEqual orderNew2.returnInfo[0].items[0].shipmentState
        expect(orderUpdated2.returnInfo[0].items[0].paymentState).toEqual orderNew2.returnInfo[0].items[0].paymentState
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
    returnInfo: []

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
  rest.DELETE url, (error, response, body) ->
    if response.statusCode is 200
      deferred.resolve JSON.parse(body)
    else if error
      deferred.reject new Error(error)
    else
      deferred.reject new Error(body)
  deferred.promise