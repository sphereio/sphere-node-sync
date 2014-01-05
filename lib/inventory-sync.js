/* ===========================================================
# sphere-node-sync - v0.3.4
# ==============================================================
# Copyright (c) 2013 Nicola Molinari
# Licensed under the MIT license.
*/
var InventorySync, Rest, Sync, helper, _,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

_ = require("underscore")._;

Rest = require("sphere-node-connect").Rest;

Sync = require("../lib/sync");

helper = require("../lib/helper");

/*
Invetory Sync class
*/


InventorySync = (function(_super) {
  __extends(InventorySync, _super);

  function InventorySync(opts) {
    if (opts == null) {
      opts = {};
    }
    InventorySync.__super__.constructor.call(this, opts);
    this;
  }

  InventorySync.prototype._doMapActions = function(diff, new_obj, old_obj) {
    var a, actions, diffVal, newVal, oldVal;
    actions = [];
    if (diff.quantityOnStock) {
      oldVal = diff.quantityOnStock[0];
      newVal = diff.quantityOnStock[1];
      diffVal = newVal - oldVal;
      a = {
        quantity: Math.abs(diffVal)
      };
      if (diffVal > 0) {
        a.action = 'addQuantity';
        actions.push(a);
      } else if (diffVal < 0) {
        a.action = 'removeQuantity';
        actions.push(a);
      }
    }
    return actions;
  };

  InventorySync.prototype._doUpdate = function(callback) {
    var payload;
    payload = JSON.stringify(this._data.update);
    return this._rest.POST("/inventory/" + this._data.updateId, payload, callback);
  };

  return InventorySync;

})(Sync);

/*
Exports object
*/


module.exports = InventorySync;
