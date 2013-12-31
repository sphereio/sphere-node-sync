/* ===========================================================
# sphere-node-sync - v0.3.0
# ==============================================================
# Copyright (c) 2013 Nicola Molinari
# Licensed under the MIT license.
*/
var InventorySync, InventoryUpdater, Q;

InventorySync = require('../lib/inventory-sync');

Q = require('q');

/*
Inventory Updater class
*/


InventoryUpdater = (function() {
  function InventoryUpdater(opts) {
    if (opts == null) {
      opts = {};
    }
    this.sync = new InventorySync(opts);
    this.rest = this.sync._rest;
    this.existingInventoryEntries = {};
    this.sku2index = {};
    this;
  }

  InventoryUpdater.prototype.createInventoryEntry = function(sku, quantity, expectedDelivery, channelId) {
    var entry;
    entry = {
      sku: sku,
      quantityOnStock: parseInt(quantity)
    };
    if (expectedDelivery) {
      entry.expectedDelivery = expectedDelivery;
    }
    if (channelId) {
      entry.supplyChannel = {
        typeId: 'channel',
        id: channelId
      };
    }
    return entry;
  };

  InventoryUpdater.prototype.ensureChannelByKey = function(rest, channelKey) {
    var deferred, query;
    deferred = Q.defer();
    query = encodeURIComponent("key=\"" + channelKey + "\"");
    rest.GET("/channels?where=" + query, function(error, response, body) {
      var channel, channels;
      if (error) {
        deferred.reject('Error on getting channel: ' + error);
        return deferred.promise;
      }
      if (response.statusCode === 200) {
        channels = JSON.parse(body).results;
        if (channels.length === 1) {
          deferred.resolve(channels[0]);
          return deferred.promise;
        }
      }
      channel = {
        key: channelKey
      };
      return rest.POST('/channels', JSON.stringify(channel), function(error, response, body) {
        var c;
        if (error) {
          return deferred.reject('Error on creating channel: ' + error);
        } else if (response.statusCode === 201) {
          c = JSON.parse(body);
          return deferred.resolve(c);
        } else {
          return deferred.reject('Problem on creating channel: ' + body);
        }
      });
    });
    return deferred.promise;
  };

  InventoryUpdater.prototype.returnResult = function(positiveFeedback, msg, callback) {
    var logLevel, retVal;
    if (this.bar) {
      this.bar.terminate();
    }
    retVal = {
      component: this.constructor.name,
      status: positiveFeedback,
      message: msg
    };
    if (this.log) {
      logLevel = positiveFeedback ? 'info' : 'err';
      this.log.log(logLevel, d);
    }
    return callback(retVal);
  };

  InventoryUpdater.prototype.allInventoryEntries = function(rest) {
    var deferred;
    deferred = Q.defer();
    rest.GET('/inventory?limit=0', function(error, response, body) {
      var stocks;
      if (error) {
        return deferred.reject('Error on getting all inventory entries: ' + error);
      } else if (response.statusCode === !200) {
        return deferred.reject('Problem on getting all inventory entries: ' + body);
      } else {
        stocks = JSON.parse(body).results;
        return deferred.resolve(stocks);
      }
    });
    return deferred.promise;
  };

  InventoryUpdater.prototype.initMatcher = function() {
    var deferred,
      _this = this;
    deferred = Q.defer();
    this.allInventoryEntries(this.rest).then(function(existingEntries) {
      var existingEntry, i, _i, _len, _ref;
      _this.existingInventoryEntries = existingEntries;
      _ref = _this.existingInventoryEntries;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        existingEntry = _ref[i];
        _this.sku2index[existingEntry.sku] = i;
      }
      return deferred.resolve(true);
    }).fail(function(msg) {
      return deferred.reject(msg);
    });
    return deferred.promise;
  };

  InventoryUpdater.prototype.match = function(s) {
    if (this.sku2index[s.sku] !== -1) {
      return this.existingInventoryEntries[this.sku2index[s.sku]];
    }
  };

  InventoryUpdater.prototype.createOrUpdate = function(inventoryEntries, callback) {
    var entry, existingEntry, posts, _i, _len,
      _this = this;
    posts = [];
    for (_i = 0, _len = inventoryEntries.length; _i < _len; _i++) {
      entry = inventoryEntries[_i];
      existingEntry = this.match(entry);
      if (existingEntry) {
        posts.push(this.update(entry, existingEntry));
      } else {
        posts.push(this.create(entry));
      }
    }
    return Q.all(posts).then(function(messages) {
      if (messages.length === 1) {
        messages = messages[0];
      } else {
        messages = "" + messages.length + " inventory entries done.";
      }
      return _this.returnResult(true, messages, callback);
    }).fail(function(msg) {
      return _this.returnResult(false, msg, callback);
    });
  };

  InventoryUpdater.prototype.update = function(entry, existingEntry) {
    var deferred,
      _this = this;
    deferred = Q.defer();
    this.sync.buildActions(entry, existingEntry).update(function(error, response, body) {
      if (_this.bar) {
        _this.bar.tick();
      }
      if (error) {
        return deferred.reject('Error on updating inventory entry: ' + error);
      } else {
        if (response.statusCode === 200) {
          return deferred.resolve('Inventory entry updated.');
        } else if (response.statusCode === 304) {
          return deferred.resolve('Inventory entry update not neccessary.');
        } else {
          return deferred.reject('Problem on updating existing inventory entry: ' + body);
        }
      }
    });
    return deferred.promise;
  };

  InventoryUpdater.prototype.create = function(stock) {
    var deferred;
    deferred = Q.defer();
    this.rest.POST('/inventory', JSON.stringify(stock), function(error, response, body) {
      if (this.bar) {
        this.bar.tick();
      }
      if (error) {
        return deferred.reject('Error on creating new inventory entry: ' + error);
      } else {
        if (response.statusCode === 201) {
          return deferred.resolve('New inventory entry created.');
        } else {
          return deferred.reject('Problem on creating new inventory entry: ' + body);
        }
      }
    });
    return deferred.promise;
  };

  return InventoryUpdater;

})();

/*
Exports object
*/


module.exports = InventoryUpdater;