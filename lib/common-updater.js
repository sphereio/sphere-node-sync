/* ===========================================================
# sphere-node-sync - v0.3.4
# ==============================================================
# Copyright (c) 2013 Nicola Molinari
# Licensed under the MIT license.
*/
var CommonUpdater, ProgressBar, logentries, _;

_ = require('underscore')._;

ProgressBar = require('progress');

logentries = require('node-logentries');

/*
(abstract) Common Updater class
*/


CommonUpdater = (function() {
  function CommonUpdater(options) {
    if (options == null) {
      options = {};
    }
    if (options.logentries_token) {
      this.log = logentries.logger({
        token: options.logentries_token
      });
    }
    if (options.show_progress === true) {
      this.showProgressBar = true;
    }
    this;
  }

  CommonUpdater.prototype.initProgressBar = function(title, size) {
    if (this.showProgressBar) {
      return this.bar = new ProgressBar("" + title + " [:bar] :current/:total (= :percent) done", {
        width: 80,
        total: size
      });
    }
  };

  CommonUpdater.prototype.tickProgress = function() {
    if (this.bar) {
      return this.bar.tick();
    }
  };

  CommonUpdater.prototype.returnResult = function(isPossitive, message, callback) {
    var logLevel, msg, retVal, summary, _i, _len;
    if (this.bar) {
      this.bar.terminate();
    }
    if (_.isArray(message)) {
      if (_.size(message) === 1) {
        message = message[0];
      } else {
        summary = {};
        for (_i = 0, _len = message.length; _i < _len; _i++) {
          msg = message[_i];
          if (!summary[msg]) {
            summary[msg] = 0;
          }
          summary[msg] = summary[msg] + 1;
        }
        message = summary;
      }
    }
    retVal = {
      component: this.constructor.name,
      status: isPossitive,
      message: message
    };
    if (this.log) {
      logLevel = isPossitive ? 'info' : 'err';
      this.log.log(logLevel, retVal);
    }
    return callback(retVal);
  };

  return CommonUpdater;

})();

/*
Exports object
*/


module.exports = CommonUpdater;
