/* ===========================================================
# sphere-node-sync - v0.3.4
# ==============================================================
# Copyright (c) 2013 Nicola Molinari
# Licensed under the MIT license.
*/
exports.getDeltaValue = function(arr) {
  var size;
  size = arr.length;
  switch (size) {
    case 1:
      return arr[0];
    case 2:
      return arr[1];
    case 3:
      return void 0;
  }
};
