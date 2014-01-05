/* ===========================================================
# sphere-node-sync - v0.3.4
# ==============================================================
# Copyright (c) 2013 Nicola Molinari
# Licensed under the MIT license.
*/
var Rest, Sync, Utils, _;

_ = require("underscore")._;

Rest = require("sphere-node-connect").Rest;

Utils = require("../lib/utils");

/*
Base Sync class
*/


Sync = (function() {
  function Sync(opts) {
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
    this;
  }

  Sync.prototype.buildActions = function(new_obj, old_obj) {
    var actions, diff, update;
    diff = this._utils.diff(old_obj, new_obj);
    update = void 0;
    if (diff) {
      actions = this._doMapActions(diff, new_obj, old_obj);
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

  Sync.prototype.get = function(key) {
    if (key == null) {
      key = "update";
    }
    return this._data[key];
  };

  Sync.prototype.update = function(callback) {
    if (!this._rest) {
      throw new Error("Cannot update: the Rest connector wasn't instantiated (probabily because of missing credentials)");
    }
    if (!_.isEmpty(this._data.update)) {
      return this._doUpdate(callback);
    } else {
      return callback(null, {
        statusCode: 304
      }, null);
    }
  };

  /*
  Methods to override
  */


  Sync.prototype._doMapActions = function(diff, new_obj, old_obj) {
    return [];
  };

  Sync.prototype._doUpdate = function(callback) {
    return callback(null, null, null);
  };

  return Sync;

})();

/*
Exports object
*/


module.exports = Sync;
