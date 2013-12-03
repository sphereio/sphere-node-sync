_ = require("underscore")._
Utils = require("../lib/utils")

describe "Utils", ->

  it "should initialize", ->
    utils = new Utils
    expect(utils).toBeDefined()

describe "Utils.diff", ->

  beforeEach ->
    @utils = new Utils

  afterEach ->
    @utils = null

  it "should return diffed object", ->
    d = @utils.diff({foo: "bar"}, {foo: "baz"})
    expect(d).toEqual foo: ["bar", "baz"]
