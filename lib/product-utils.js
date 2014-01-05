/* ===========================================================
# sphere-node-sync - v0.3.4
# ==============================================================
# Copyright (c) 2013 Nicola Molinari
# Licensed under the MIT license.
*/
var ProductUtils, Utils, actionsList, buildAddPriceAction, buildNewSetAttributeAction, buildRemovePriceAction, buildSetAttributeAction, helper, jsondiffpatch, _, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

_ = require("underscore")._;

jsondiffpatch = require("jsondiffpatch");

Utils = require("../lib/utils");

helper = require("../lib/helper");

/*
Product Utils class
*/


ProductUtils = (function(_super) {
  __extends(ProductUtils, _super);

  function ProductUtils() {
    _ref = ProductUtils.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  ProductUtils.prototype.diff = function(old_obj, new_obj) {
    var patchPrices;
    patchPrices = function(obj) {
      if (obj.masterVariant) {
        if (obj.masterVariant.prices && obj.masterVariant.prices.length > 0) {
          _.each(obj.masterVariant.prices, function(p, i) {
            return p._id = i;
          });
        }
      }
      if (obj.variants && obj.variants.length > 0) {
        return _.each(obj.variants, function(v) {
          if (v.prices && v.prices.length > 0) {
            return _.each(v.prices, function(p, i) {
              return p._id = i;
            });
          }
        });
      }
    };
    patchPrices(old_obj);
    patchPrices(new_obj);
    return ProductUtils.__super__.diff.call(this, old_obj, new_obj);
  };

  ProductUtils.prototype.actionsMap = function(diff, old_obj) {
    var actions;
    actions = [];
    _.each(actionsList(), function(item) {
      var a, action, key, keys, obj, old, updated;
      key = item.key;
      action = (function() {
        switch (key) {
          case "name":
          case "slug":
          case "description":
            obj = diff[key];
            if (obj) {
              updated = {};
              if (_.isArray(obj)) {
                updated = helper.getDeltaValue(obj);
              } else {
                keys = _.keys(obj);
                _.each(keys, function(k) {
                  var value;
                  value = helper.getDeltaValue(obj[k]);
                  return updated[k] = value;
                });
              }
              old = _.clone(old_obj[key]);
              _.extend(old, updated);
              a = {
                action: item.action
              };
              if (updated) {
                a[key] = old;
              } else {
                a[key] = void 0;
              }
              return a;
            }
        }
      })();
      if (action) {
        return actions.push(action);
      }
    });
    return actions;
  };

  ProductUtils.prototype.actionsMapPrices = function(diff, old_obj, new_obj) {
    var actions, prices;
    actions = [];
    if (diff.masterVariant) {
      prices = diff.masterVariant.prices;
      if (prices) {
        _.each(prices, function(value, key) {
          var addAction, index, removeAction;
          if (key.match(/^\d$/g)) {
            index = key;
          } else if (key.match(/^\_\d$/g)) {
            index = key.substring(1);
          }
          if (index) {
            removeAction = buildRemovePriceAction(old_obj.masterVariant, index);
            if (removeAction) {
              actions.push(removeAction);
            }
            addAction = buildAddPriceAction(new_obj.masterVariant, index);
            if (addAction) {
              return actions.push(addAction);
            }
          }
        });
      }
    }
    if (diff.variants) {
      _.each(diff.variants, function(variant, i) {
        prices = variant.prices;
        if (prices) {
          return _.each(prices, function(value, key) {
            var addAction, index, removeAction;
            if (key.match(/^\d$/g)) {
              index = key;
            } else if (key.match(/^\_\d$/g)) {
              index = key.substring(1);
            }
            if (index) {
              removeAction = buildRemovePriceAction(old_obj.variants[i], index);
              if (removeAction) {
                actions.push(removeAction);
              }
              addAction = buildAddPriceAction(new_obj.variants[i], index);
              if (addAction) {
                return actions.push(addAction);
              }
            }
          });
        }
      });
    }
    return _.sortBy(actions, function(a) {
      return a.action === "addPrice";
    });
  };

  ProductUtils.prototype.actionsMapAttributes = function(diff, new_obj) {
    var actions, attributes, masterVariant;
    actions = [];
    masterVariant = diff.masterVariant;
    if (masterVariant) {
      attributes = masterVariant.attributes;
      if (attributes) {
        _.each(attributes, function(value, key) {
          var id, index, setAction, v;
          if (key.match(/^\d$/g)) {
            if (_.isArray(value)) {
              v = helper.getDeltaValue(value);
              id = new_obj.masterVariant.id;
              setAction = buildNewSetAttributeAction(id, v);
              if (setAction) {
                return actions.push(setAction);
              }
            } else {
              index = key;
              setAction = buildSetAttributeAction(value.value, new_obj.masterVariant, index);
              if (setAction) {
                return actions.push(setAction);
              }
            }
          }
        });
      }
    }
    if (diff.variants) {
      _.each(diff.variants, function(variant, i) {
        attributes = variant.attributes;
        if (attributes) {
          return _.each(attributes, function(value, key) {
            var id, index, setAction, v;
            if (key.match(/^\d$/g)) {
              if (_.isArray(value)) {
                v = helper.getDeltaValue(value);
                id = new_obj.variants[i].id;
                setAction = buildNewSetAttributeAction(id, v);
                if (setAction) {
                  return actions.push(setAction);
                }
              } else {
                index = key;
                setAction = buildSetAttributeAction(value.value, new_obj.variants[i], index);
                if (setAction) {
                  return actions.push(setAction);
                }
              }
            } else if (key.match(/^\_\d$/g)) {
              if (_.isArray(value)) {
                v = helper.getDeltaValue(value);
                if (!v) {
                  v = value[0];
                  delete v.value;
                }
                id = new_obj.variants[i].id;
                setAction = buildNewSetAttributeAction(id, v);
                if (setAction) {
                  return actions.push(setAction);
                }
              } else {
                index = key.substring(1);
                setAction = buildSetAttributeAction(value.value, new_obj.variants[i], index);
                if (setAction) {
                  return actions.push(setAction);
                }
              }
            }
          });
        }
      });
    }
    return actions;
  };

  return ProductUtils;

})(Utils);

/*
Exports object
*/


module.exports = ProductUtils;

actionsList = function() {
  return [
    {
      action: "changeName",
      key: "name"
    }, {
      action: "changeSlug",
      key: "slug"
    }, {
      action: "setDescription",
      key: "description"
    }
  ];
};

buildRemovePriceAction = function(variant, index) {
  var action, price;
  price = variant.prices[index];
  if (price) {
    delete price._id;
    action = {
      action: "removePrice",
      variantId: variant.id,
      price: price
    };
  }
  return action;
};

buildAddPriceAction = function(variant, index) {
  var action, price;
  price = variant.prices[index];
  if (price) {
    delete price._id;
    action = {
      action: "addPrice",
      variantId: variant.id,
      price: price
    };
  }
  return action;
};

buildSetAttributeAction = function(diffed_value, variant, index) {
  var action, attribute, centAmount, currencyCode, lab, label, text;
  attribute = variant.attributes[index];
  if (attribute) {
    action = {
      action: "setAttribute",
      variantId: variant.id,
      name: attribute.name
    };
    if (_.isArray(diffed_value)) {
      action.value = helper.getDeltaValue(diffed_value);
    } else {
      if (_.isString(diffed_value)) {
        action.value = helper.getDeltaValue(diffed_value);
      } else if (diffed_value.label) {
        lab = diffed_value.label;
        if (_.isArray(lab)) {
          label = helper.getDeltaValue(lab);
        } else {
          label = {};
          _.each(lab, function(v, k) {
            return label[k] = helper.getDeltaValue(v);
          });
        }
        action.value = {
          label: label,
          key: helper.getDeltaValue(diffed_value.key) || attribute.value.key
        };
      } else if (diffed_value.centAmount) {
        if (diffed_value.centAmount) {
          centAmount = helper.getDeltaValue(diffed_value.centAmount);
        } else {
          centAmount = attribute.value.centAmount;
        }
        if (diffed_value.currencyCode) {
          currencyCode = helper.getDeltaValue(diffed_value.currencyCode);
        } else {
          currencyCode = attribute.value.currencyCode;
        }
        action.value = {
          centAmount: centAmount,
          currencyCode: currencyCode
        };
      } else {
        if (diffed_value.key) {
          action.value = {
            label: attribute.value.label,
            key: helper.getDeltaValue(diffed_value.key)
          };
        } else {
          text = {};
          _.each(diffed_value, function(v, k) {
            return text[k] = helper.getDeltaValue(v);
          });
          action.value = text;
        }
      }
    }
  }
  return action;
};

buildNewSetAttributeAction = function(id, el) {
  var action;
  action = {
    action: "setAttribute",
    variantId: id,
    name: el.name,
    value: el.value
  };
  return action;
};
