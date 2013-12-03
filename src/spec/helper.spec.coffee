_ = require("underscore")._
helper = require("../lib/helper")

describe "Helper", ->

  _.each ["new", "update", "delete"], (key)->
    it "should get delta value for '#{key}' value", ->
      switch key
        when "new"
          delta = ["bar"]
          expect(helper.getDeltaValue(delta)).toBe "bar"
        when "update"
          delta = ["bar", "qux"]
          expect(helper.getDeltaValue(delta)).toBe "qux"
        when "delete"
          delta = ["bar", 0, 0]
          expect(helper.getDeltaValue(delta)).not.toBeDefined()
