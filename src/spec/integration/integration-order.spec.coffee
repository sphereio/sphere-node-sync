_ = require('underscore')._
_.mixin deepClone: (obj) -> JSON.parse(JSON.stringify(obj))
Q = require 'q'
OrderSync = require '../../lib/sync/order-sync'
Config = require('../../config').config
order = require '../../models/order.json'

describe "Integration test", ->

  beforeEach (done) ->
    @sync = new OrderSync
      config: Config.staging
      logConfig:
        levelStream: 'error'
        levelFile: 'error'

    # get a tax category required for setting up shippingInfo (simply returning first found)
    createResourcePromise(@sync._rest, '/tax-categories', taxCategoryMock())
      .then (taxCategory) =>
        @taxCategory = taxCategory
        createResourcePromise(@sync._rest, '/zones', zoneMock())
    .then (zone) =>
      @zone = zone
      createResourcePromise(@sync._rest, '/shipping-methods', shippingMethodMock(@zone, @taxCategory))
    .then (shippingMethod) =>
      @shippingMethod = shippingMethod
      createResourcePromise(@sync._rest, '/product-types', productTypeMock())
    .then (productType) =>
      @productType = productType
      createResourcePromise(@sync._rest, '/products', productMock(productType))
    .then (product) =>
      @product = product
      createResourcePromise(@sync._rest, '/orders/import', orderMock(@shippingMethod, product, @taxCategory))
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

  it 'should update an order', (done) ->
    orderNew = _.deepClone @order

    orderNew.orderState = 'Complete'
    orderNew.paymentState = 'Paid'
    orderNew.shipmentState = 'Ready'

    @sync.buildActions(orderNew, @order).update (error, response, body) ->
      expect(response.statusCode).toBe 200
      console.error body unless response.statusCode is 200
      orderUpdated = body
      expect(orderUpdated).toBeDefined()
      expect(orderUpdated.orderState).toBe orderNew.orderState
      expect(orderUpdated.paymentState).toBe orderNew.paymentState
      expect(orderUpdated.shipmentState).toBe orderNew.shipmentState
      done()

  it 'should sync returnInfo', (done) ->
    orderNew = _.deepClone @order

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
      orderUpdated = body
      expect(orderUpdated).toBeDefined()
      expect(orderUpdated.returnInfo[0].id).toBe orderNew.returnInfo[0].id

      done()

  it 'should sync returnInfo status', (done) ->
    orderNew = _.deepClone @order

    orderNew.returnInfo.push
      returnTrackingId: 'bla blubb'
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
      orderUpdated = body
      orderNew2 = _.deepClone orderUpdated

      orderNew2.returnInfo[0].items[0].shipmentState = 'BackInStock'
      orderNew2.returnInfo[0].items[0].paymentState = 'Refunded'

      # update returnInfo status
      @sync.buildActions(orderNew2, orderUpdated).update (error, response, body) ->

        expect(response.statusCode).toBe 200
        console.error body unless response.statusCode is 200
        orderUpdated2 = body

        expect(orderUpdated2).toBeDefined()
        expect(orderUpdated2.returnInfo[0].items[0].shipmentState).toEqual orderNew2.returnInfo[0].items[0].shipmentState
        expect(orderUpdated2.returnInfo[0].items[0].paymentState).toEqual orderNew2.returnInfo[0].items[0].paymentState
        done()

  it "should sync delivery items", (done) ->

    orderNew = JSON.parse(JSON.stringify(@order))

    # add one delivery item
    orderNew.shippingInfo.deliveries = [
      items: [{
         id: orderNew.lineItems[0].id
         quantity: 1
      }]]

    @sync.buildActions(orderNew, @order).update (error, response, body) ->
      expect(response.statusCode).toBe 200
      console.error body unless response.statusCode is 200
      orderUpdated = body

      expect(orderUpdated).toBeDefined()
      expect(_.size orderUpdated.shippingInfo.deliveries).toBe 1

      done()

  it "should sync parcel items of a delivery", (done) ->

    orderNew = JSON.parse(JSON.stringify(@order))

    # add one delivery item
    orderNew.shippingInfo.deliveries = [
      items: [{
         id: orderNew.lineItems[0].id
         quantity: 1
      }]]

    @sync.buildActions(orderNew, @order).update (error, response, body) =>
      expect(response.statusCode).toBe 200
      console.error body unless response.statusCode is 200
      orderUpdated = body

      orderNew2 = JSON.parse(JSON.stringify(orderUpdated))


      # add a parcel item
      orderNew2.shippingInfo.deliveries[0].parcels = [{
        measurements: {
          heightInMillimeter: 200
          lengthInMillimeter: 200
          widthInMillimeter: 200
          weightInGram: 200
        },
        trackingData: {
          trackingId: '1Z6185W16894827591'
          carrier: 'UPS'
          provider: 'shipcloud.io'
          providerTransaction: '549796981774cd802e9636ded5608bfa1ecce9ad'
          isReturn: true
        }
      }]

      # sync first parcel
      @sync.buildActions(orderNew2, orderUpdated).update (error, response, body) =>
        
        expect(response.statusCode).toBe 200
        console.error body unless response.statusCode is 200
        orderUpdated2 = body

        orderNew3 = JSON.parse(JSON.stringify(orderUpdated2))

        # add a parcel item
        orderNew3.shippingInfo.deliveries[0].parcels.push
          measurements:
            heightInMillimeter: 200
            lengthInMillimeter: 200
            widthInMillimeter: 200
            weightInGram: 200
          trackingData:
            trackingId: '1Z6185W16894827591'
            carrier: 'UPS'
            provider: 'shipcloud.io'
            providerTransaction: '549796981774cd802e9636ded5608bfa1ecce9ad'
            isReturn: true

        # sync a second parcel
        @sync.buildActions(orderNew3, orderUpdated2).update (error, response, body) ->
          
          expect(response.statusCode).toBe 200
          console.error body unless response.statusCode is 200
          orderUpdated3 = body

          expect(orderUpdated3).toBeDefined()
          parcels = _.first(orderUpdated3.shippingInfo.deliveries).parcels
          expect(_.size(parcels)).toBe 2
          done()

###
helper methods
###

shippingMethodMock = (zone, taxCategory) ->
  unique = new Date().getTime()
  shippingMethod =
    name: "S-#{unique}"
    zoneRates: [{
      zone:
        typeId: 'zone'
        id: zone.id
        shippingRates: [{
          price:
            currencyCode: 'EUR'
            centAmount: 99
          }]
      }]
    isDefault: false
    taxCategory:
      typeId: 'tax-category'
      id: taxCategory.id


zoneMock = ->
  unique = new Date().getTime()
  zone =
    name: "Z-#{unique}"

taxCategoryMock = ->
  unique = new Date().getTime()
  taxCategory =
    name: "TC-#{unique}"
    rates: [{
        name: "5%",
        amount: 0.05,
        includedInPrice: false,
        country: "DE",
        id: "jvzkDxzl"
      }]

productTypeMock = ->
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

orderMock = (shippingMethod, product, taxCategory) ->
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
    shippingInfo:
      shippingMethodName: 'UPS'
      price:
        currencyCode: 'EUR'
        centAmount: 99
      shippingRate:
        price:
          currencyCode: 'EUR'
          centAmount: 99
      taxRate: _.first taxCategory.rates
      taxCategory:
        typeId: 'tax-category'
        id: taxCategory.id
      shippingMethod:
        typeId: 'shipping-method'
        id: shippingMethod.id

promisifyGet = (rest, url) ->
  deferred = Q.defer()
  rest.GET url, (error, response, body) ->
    if response.statusCode is 200
      deferred.resolve body
    else if error
      deferred.reject new Error(error)
    else
      deferred.reject new Error(body)
  deferred.promise

createResourcePromise = (rest, url, body) ->
  deferred = Q.defer()
  rest.POST url, JSON.stringify(body), (error, response, body) ->
    if response.statusCode is 201
      deferred.resolve body
    else if error
      deferred.reject new Error(error)
    else
      deferred.reject new Error(body)
  deferred.promise

deleteResourcePromise = (rest, url) ->
  deferred = Q.defer()
  rest.DELETE url, (error, response, body) ->
    if response.statusCode is 200
      deferred.resolve body
    else if error
      deferred.reject new Error(error)
    else
      deferred.reject new Error(body)
  deferred.promise
