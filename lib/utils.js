/* ===========================================================
# sphere-node-sync - v0.3.4
# ==============================================================
# Copyright (c) 2013 Nicola Molinari
# Licensed under the MIT license.
*/
var Utils, jsondiffpatch, _;

_ = require("underscore")._;

jsondiffpatch = require("jsondiffpatch");

/*
Base Utils class
*/


Utils = (function() {
  function Utils() {}

  Utils.prototype.diff = function(old_obj, new_obj) {
    jsondiffpatch.config.objectHash = function(obj) {
      return obj.id || obj._id || obj.name;
    };
    return jsondiffpatch.diff(old_obj, new_obj);
  };

  return Utils;

})();

/*
Exports object
*/


module.exports = Utils;
