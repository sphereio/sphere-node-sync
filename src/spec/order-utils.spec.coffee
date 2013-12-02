OrderUtils = require("../lib/order-utils")

###
Match different order statuses
###
OLD_ORDER =
  id: "123"
  orderState: "Open"
  paymentState: "Pending"
  shipmentState: "Pending"

NEW_ORDER =
  id: "123"
  orderState: "Complete"
  paymentState: "Paid"
  shipmentState: "Ready"

describe "OrderUtils.actionsMapStatuses", ->
  beforeEach ->
    @utils = new OrderUtils

  it "should build statuses actions", ->
    delta = @utils.diff(OLD_ORDER, NEW_ORDER)
    expected_delta =
      orderState: ["Open", "Complete"]
      paymentState: ["Pending", "Paid"]
      shipmentState: ["Pending", "Ready"]
    expect(delta).toEqual expected_delta

    update = @utils.actionsMapStatuses(delta, NEW_ORDER)
    expected_update =
      [
        { action: "changeOrderState", orderState: "Complete" }
        { action: "changePaymentState", paymentState: "Paid" }
        { action: "changeShipmentState", shipmentState: "Ready" }
      ]
    expect(update).toEqual expected_update
