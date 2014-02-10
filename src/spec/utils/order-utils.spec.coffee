OrderUtils = require("../../lib/utils/order-utils")

uniqueId = (prefix = '') ->
  "#{prefix}#{new Date().getTime()}"

###
Match different order statuses
###
order =
  id: "123"
  orderState: "Open"
  paymentState: "Pending"
  shipmentState: "Pending"
  lineItems: [ {
    productId: uniqueId 'p'
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
  returnInfo: [{
    returnTrackingId: "bla blubb"
    returnDate: new Date().toISOString()
    items: [{
      id: uniqueId 'ri'
      quantity: 11
      lineItemId: 1
      comment: 'Product doesnt have enough mojo.'
      shipmentState: 'Advised'
      paymentState: 'Initial'
    }
    {
      id: uniqueId 'ri'
      quantity: 22
      lineItemId: 2
      comment: 'Product too small.'
      shipmentState: 'Advised'
      paymentState: 'Initial'
    }
    {
      id: uniqueId 'ri'
      quantity: 33
      lineItemId: 3
      comment: 'Product too big.'
      shipmentState: 'Advised'
      paymentState: 'Initial'
    }]}]

describe "OrderUtils.actionsMapStatusValues", ->
  beforeEach ->
    @utils = new OrderUtils
    @order = JSON.parse(JSON.stringify(order))

  afterEach ->
    @utils = null
    @order = null

  it "should return required actions for syncing status", ->

    orderChanged = JSON.parse(JSON.stringify(@order))
    orderChanged.orderState = "Complete"
    orderChanged.paymentState = "Paid"
    orderChanged.shipmentState = "Ready"

    delta = @utils.diff(@order, orderChanged)
    update = @utils.actionsMapStatusValues(delta, orderChanged)

    expected_update =
      [
        { action: "changeOrderState", orderState: orderChanged.orderState }
        { action: "changePaymentState", paymentState: orderChanged.paymentState }
        { action: "changeShipmentState", shipmentState: orderChanged.shipmentState }
      ]
    expect(update).toEqual expected_update


  it "should return required actions for syncing returnInfo", ->

    @order = JSON.parse(JSON.stringify(order))
    orderChanged = JSON.parse(JSON.stringify(order))

    # empty returnInfo list
    @order.returnInfo = []

    delta = @utils.diff(@order, orderChanged)
    update = @utils.actionsMapReturnInfo(delta, orderChanged)

    action = JSON.parse(JSON.stringify(orderChanged.returnInfo[0]))
    action["action"] = "addReturnInfo"

    expect(update).toEqual [action]

  it "should return required action for syncing shipmentState (returnInfo)", ->

    orderChanged = JSON.parse(JSON.stringify(@order))
    orderChanged.returnInfo[0].items[0].shipmentState = "Returned"
    orderChanged.returnInfo[0].items[1].shipmentState = "Unusable"

    delta = @utils.diff(@order, orderChanged)
    update = @utils.actionsMapReturnInfo(delta, orderChanged)
    expectedUpdate =
      [
        {
          action: "setReturnShipmentState"
          returnItemId: orderChanged.returnInfo[0].items[0].id
          shipmentState: orderChanged.returnInfo[0].items[0].shipmentState
        }
        {
          action: "setReturnShipmentState"
          returnItemId: orderChanged.returnInfo[0].items[1].id
          shipmentState: orderChanged.returnInfo[0].items[1].shipmentState
        }
      ]
    expect(update).toEqual expectedUpdate

  it "should return required action for syncing paymentState (returnInfo)", ->

    orderChanged = JSON.parse(JSON.stringify(@order))
    orderChanged.returnInfo[0].items[0].paymentState = "Refunded"
    orderChanged.returnInfo[0].items[1].paymentState = "NotRefunded"

    delta = @utils.diff(@order, orderChanged)

    update = @utils.actionsMapReturnInfo(delta, orderChanged)
    expectedUpdate =
      [
        {
          action: "setReturnPaymentState"
          returnItemId: orderChanged.returnInfo[0].items[0].id
          paymentState: orderChanged.returnInfo[0].items[0].paymentState
        }
        {
          action: "setReturnPaymentState"
          returnItemId: orderChanged.returnInfo[0].items[1].id
          paymentState: orderChanged.returnInfo[0].items[1].paymentState
        }
      ]
    expect(update).toEqual expectedUpdate

  it "should return required actions for syncing returnInfo and shipmentState", ->

    orderChanged = JSON.parse(JSON.stringify(@order))

    # add a 2nd returnInfo
    orderChanged.returnInfo.push
      returnTrackingId: "bla blubb"
      returnDate: new Date().toISOString()
      items: [{
        id: uniqueId 'ri'
        quantity: 111
        lineItemId: 1
        comment: 'Product doesnt have enough mojo.'
        shipmentState: 'Advised'
        paymentState: 'Initial'
      }
      {
        id: uniqueId 'ri'
        quantity: 222
        lineItemId: 2
        comment: 'Product too small.'
        shipmentState: 'Advised'
        paymentState: 'Initial'
      }
      {
        id: uniqueId 'ri'
        quantity: 333
        lineItemId: 3
        comment: 'Product too big.'
        shipmentState: 'Advised'
        paymentState: 'Initial'
      }]

    # change shipment status of existing returnInfo
    orderChanged.returnInfo[0].items[0].shipmentState = "Returned"
    orderChanged.returnInfo[0].items[1].shipmentState = "Unusable"

    delta = @utils.diff(@order, orderChanged)
    update = @utils.actionsMapReturnInfo(delta, orderChanged)

    addAction = JSON.parse(JSON.stringify(orderChanged.returnInfo[1]))
    addAction["action"] = "addReturnInfo"

    expectedUpdate =
      [
        {
          action: "setReturnShipmentState"
          returnItemId: orderChanged.returnInfo[0].items[0].id
          shipmentState: orderChanged.returnInfo[0].items[0].shipmentState
        }
        {
          action: "setReturnShipmentState"
          returnItemId: orderChanged.returnInfo[0].items[1].id
          shipmentState: orderChanged.returnInfo[0].items[1].shipmentState
        }
        addAction
      ]


    expect(update).toEqual expectedUpdate
