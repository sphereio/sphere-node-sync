_ = require("underscore")._
Sync = require("../lib/sync")
Config = require("../config").config.prod

OLD_OBJ =
  id: "123"
  foo: "bar"
  version: 1

NEW_OBJ =
  id: "123"
  foo: "qux"
  version: 1

describe "Sync", ->

  it "should initialize", ->
    sync = new Sync
    expect(sync).toBeDefined()
    expect(sync._actions).not.toBeDefined()

  it "should initialize with options", ->
    sync = new Sync config: Config
    expect(sync).toBeDefined()
    expect(sync._rest).toBeDefined()
    expect(sync._rest._options.config).toEqual Config

  it "should throw error if no credentials are given", ->
    sync = -> new Sync foo: "bar"
    expect(sync).toThrow new Error("Missing credentials")

  _.each ["client_id", "client_secret", "project_key"], (key)->
    it "should throw error if no '#{key}' is defined", ->
      opt = _.clone(Config)
      delete opt[key]
      sync = -> new Sync config: opt
      expect(sync).toThrow new Error("Missing '#{key}'")


describe "Sync.buildActions", ->

  beforeEach ->
    @sync = new Sync

  afterEach ->
    @sync = null

  it "should return reference to the object", ->
    s = @sync.buildActions(NEW_OBJ, OLD_OBJ)
    expect(s).toEqual @sync

  it "should build empty action update", ->
    update = @sync.buildActions(NEW_OBJ, OLD_OBJ).get()
    expect(update).not.toBeDefined()


describe "Sync.get", ->

  beforeEach ->
    @sync = new Sync
    @sync._data =
      update: "a"
      updateId: "123"

  afterEach ->
    @sync = null

  it "should get data key", ->
    expect(@sync.get("update")).toBe "a"
    expect(@sync.get("updateId")).toBe "123"
    expect(@sync.get("foo")).not.toBeDefined()

  it "should get default data key", ->
    expect(@sync.get()).toBe "a"

describe "Sync.update", ->

  beforeEach ->
    @sync = new Sync config: Config

  afterEach ->
    @sync = null

  it "should throw error if no credentials were given", ->
    sync = new Sync
    expect(sync.update).toThrow new Error("Cannot update: the Rest connector wasn't instantiated (probabily because of missing credentials)")

  it "should send update request", (done)->
    spyOn(@sync._rest, "POST")
    @sync._data =
      update:
        actions: []
        version: 1
      updateId: "123"
    callMe = (e, r, b)->
      expect(e).toBe null
      expect(r).toBe null
      expect(b).toBe null
      done()
    @sync.update(callMe)
    expect(@sync._rest.POST).not.toHaveBeenCalled()

  it "should return '304' if there are no update actions", (done)->
    spyOn(@sync._rest, "POST")
    callMe = (e, r, b)->
      expect(e).toBe null
      expect(r.statusCode).toBe 304
      expect(b).toBe null
      done()
    @sync.update(callMe)
    expect(@sync._rest.POST).not.toHaveBeenCalled()
