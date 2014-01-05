/* ===========================================================
# sphere-node-sync - v0.3.4
# ==============================================================
# Copyright (c) 2013 Nicola Molinari
# Licensed under the MIT license.
*/
var ProductSync, ProductUtils, Rest, Sync, _,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

_ = require("underscore")._;

Rest = require("sphere-node-connect").Rest;

Sync = require("../lib/sync");

ProductUtils = require("../lib/product-utils");

/*
Product Sync class
*/


ProductSync = (function(_super) {
  __extends(ProductSync, _super);

  function ProductSync(opts) {
    if (opts == null) {
      opts = {};
    }
    ProductSync.__super__.constructor.call(this, opts);
    this._utils = new ProductUtils;
    this;
  }

  ProductSync.prototype._doMapActions = function(diff, new_obj, old_obj) {
    var actions, actionsAttributes, actionsPrices;
    actions = this._utils.actionsMap(diff, old_obj);
    actionsPrices = this._utils.actionsMapPrices(diff, old_obj, new_obj);
    actionsAttributes = this._utils.actionsMapAttributes(diff, new_obj);
    actions = _.union(actions, actionsPrices, actionsAttributes);
    return actions;
  };

  ProductSync.prototype._doUpdate = function(callback) {
    var payload;
    payload = JSON.stringify(this._data.update);
    return this._rest.POST("/products/" + this._data.updateId, payload, callback);
  };

  return ProductSync;

})(Sync);

/*
Exports object
*/


module.exports = ProductSync;
