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
  returnInfo:
    returnTrackingId: "bla blubb"
    returnDate: new Date()
    items: [{
      id: uniqueId 'ri'
      quantity: 1
      lineItemId: 1
      comment: 'Product doesnt have enough mojo.'
      shipmentState: 'Advised'
      paymentState: 'Initial'
    }]

describe "OrderUtils.actionsMapStatuses", ->
  beforeEach ->
    @utils = new OrderUtils
    @order = order

  it "should return required actions for syncing status", ->

    orderChanged = JSON.parse(JSON.stringify(@order))
    orderChanged.orderState = "Complete"
    orderChanged.paymentState = "Paid"
    orderChanged.shipmentState = "Ready"

    delta = @utils.diff(@order, orderChanged)
    update = @utils.actionsMapStatuses(delta, orderChanged)

    expected_update =
      [
        { action: "changeOrderState", orderState: orderChanged.orderState }
        { action: "changePaymentState", paymentState: orderChanged.paymentState }
        { action: "changeShipmentState", shipmentState: orderChanged.shipmentState }
      ]
    expect(update).toEqual expected_update


  it "should return required actions for syncing returnInfo", ->

    @order = JSON.parse(JSON.stringify(@order))
    orderChanged = JSON.parse(JSON.stringify(order))

    # remove returnInfo key/value
    delete @order.returnInfo

    delta = @utils.diff(@order, orderChanged)
    update = @utils.actionMapReturnInfo(delta, orderChanged)

    action = JSON.parse(JSON.stringify(orderChanged.returnInfo))
    action["action"] = "addReturnInfo"

    expect(update).toEqual [action]

  it "should return required action for syncing shipmentState (returnInfo)", ->

    orderChanged = JSON.parse(JSON.stringify(@order))
    orderChanged.returnInfo.items[0].shipmentState = "Returned"

    delta = @utils.diff(@order, orderChanged)
    update = @utils.actionMapReturnInfo(delta, orderChanged)
    expectedUpdate =
      [
        {
          action: "setReturnShipmentState"
          returnItemId: orderChanged.returnInfo.items[0].id
          shipmentState: orderChanged.returnInfo.items[0].shipmentState
        }
      ]
    expect(update).toEqual expectedUpdate

  it "should return required action for syncing paymentState (returnInfo)", ->

    orderChanged = JSON.parse(JSON.stringify(@order))
    orderChanged.returnInfo.items[0].paymentState = "Refunded"


    delta = @utils.diff(@order, orderChanged)
    update = @utils.actionMapReturnInfo(delta, orderChanged)
    expectedUpdate =
      [
        {
          action: "setReturnPaymentState"
          returnItemId: orderChanged.returnInfo.items[0].id
          paymentState: orderChanged.returnInfo.items[0].paymentState
        }
      ]
    expect(update).toEqual expectedUpdate
