/* ===========================================================
# sphere-node-sync - v0.3.4
# ==============================================================
# Copyright (c) 2013 Nicola Molinari
# Licensed under the MIT license.
*/
var OrderUtils, Utils, actionsList, helper, jsondiffpatch, _, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

_ = require("underscore")._;

jsondiffpatch = require("jsondiffpatch");

Utils = require("../lib/utils");

helper = require("../lib/helper");

/*
Order Utils class
*/


OrderUtils = (function(_super) {
  __extends(OrderUtils, _super);

  function OrderUtils() {
    _ref = OrderUtils.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  OrderUtils.prototype.actionsMapStatuses = function(diff, old_obj) {
    var actions;
    actions = [];
    _.each(actionsList(), function(item) {
      var action, key, obj, updated;
      key = item.key;
      obj = diff[key];
      if (obj) {
        updated = helper.getDeltaValue(obj);
        action = {
          action: item.action
        };
        action[key] = updated;
      }
      if (action) {
        return actions.push(action);
      }
    });
    return actions;
  };

  return OrderUtils;

})(Utils);

/*
Exports object
*/


module.exports = OrderUtils;

actionsList = function() {
  return [
    {
      action: "changeOrderState",
      key: "orderState"
    }, {
      action: "changePaymentState",
      key: "paymentState"
    }, {
      action: "changeShipmentState",
      key: "shipmentState"
    }
  ];
};
