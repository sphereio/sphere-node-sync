/* ===========================================================
# sphere-node-sync - v0.0.1
# ==============================================================
# Copyright (c) 2013 Nicola Molinari
# Licensed under the MIT license.
*/
var OrderSync, ProductUtils, Rest, Sync, _,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

_ = require("underscore")._;

Rest = require("sphere-node-connect").Rest;

Sync = require("../lib/sync");

ProductUtils = require("../lib/product-utils");

/*
Order Sync class
*/


OrderSync = (function(_super) {
  __extends(OrderSync, _super);

  function OrderSync(opts) {
    if (opts == null) {
      opts = {};
    }
    OrderSync.__super__.constructor.call(this, opts);
    this._utils = new OrderUtils;
    this;
  }

  OrderSync.prototype._doMapActions = function(diff, new_obj, old_obj) {
    var actions;
    actions = this._utils.actionsMapStatuses(diff, old_obj);
    return actions;
  };

  OrderSync.prototype._doUpdate = function(callback) {
    var payload;
    payload = JSON.stringify(this._data.update);
    return this._rest.POST("/orders/" + this._data.updateId, payload, callback);
  };

  return OrderSync;

})(Sync);

/*
Exports object
*/


module.exports = OrderSync;
