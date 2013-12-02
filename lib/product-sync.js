/* ===========================================================
# sphere-node-sync - v0.0.1
# ==============================================================
# Copyright (c) 2013 Nicola Molinari
# Licensed under the MIT license.
*/
var Rest, Utils, _;

_ = require("underscore")._;

Rest = require("sphere-node-connect").Rest;

Utils = require("../lib/utils").Utils;

exports.ProductSync = function(opts) {
  var config;
  if (opts == null) {
    opts = {};
  }
  if (!_.isEmpty(opts)) {
    config = opts.config;
    if (!config) {
      throw new Error("Missing credentials");
    }
    if (!config.client_id) {
      throw new Error("Missing 'client_id'");
    }
    if (!config.client_secret) {
      throw new Error("Missing 'client_secret'");
    }
    if (!config.project_key) {
      throw new Error("Missing 'project_key'");
    }
    this._rest = new Rest(opts);
  }
  this._data = {};
  this._utils = new Utils;
};

exports.ProductSync.prototype.buildActions = function(new_obj, old_obj) {
  var actions, actionsAttributes, actionsPrices, diff, update;
  diff = this._utils.diff(old_obj, new_obj);
  update = void 0;
  if (diff) {
    actions = this._utils.actionsMap(diff, old_obj);
    actionsPrices = this._utils.actionsMapPrices(diff, old_obj, new_obj);
    actionsAttributes = this._utils.actionsMapAttributes(diff, new_obj);
    actions = _.union(actions, actionsPrices, actionsAttributes);
    if (actions.length > 0) {
      update = {
        actions: actions,
        version: old_obj.version
      };
    }
  }
  this._data = {
    update: update,
    updateId: old_obj.id
  };
  return this;
};

exports.ProductSync.prototype.get = function(key) {
  if (key == null) {
    key = "update";
  }
  return this._data[key];
};

exports.ProductSync.prototype.update = function(callback) {
  var payload;
  if (!this._rest) {
    throw new Error("Cannot update: the Rest connector wasn't instantiated (probabily because of missing credentials)");
  }
  if (!_.isEmpty(this._data.update)) {
    payload = JSON.stringify(this._data.update);
    return this._rest.POST("/products/" + this._data.updateId, payload, callback);
  } else {
    return callback(null, {
      statusCode: 304
    }, null);
  }
};
