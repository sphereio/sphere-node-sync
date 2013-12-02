_ = require("underscore")._
Sync = require("../lib/sync").Sync
Config = require("../config").config.prod
product = require("../models/product.json")

OLD_PRODUCT =
  id: "123"
  version: 1
  name:
    en: "SAPPHIRE"
    de: "Hoo"
  slug:
    en: "sapphire1366126441922"
  description:
    en: "Sample description"
  masterVariant:
    id: 1
    prices: [
      {value: {currencyCode: "EUR", centAmount: 100}},
      {value: {currencyCode: "EUR", centAmount: 1000}},
      {value: {currencyCode: "EUR", centAmount: 1100}, country: "DE"},
      {value: {currencyCode: "EUR", centAmount: 1200}, customerGroup: {id: "984a64de-24a4-42c0-868b-da7abfe1c5f6", typeId: "customer-group"}}
    ]
  variants: [
    {
      id: 2
      prices: [
        {value: {currencyCode: "EUR", centAmount: 100}},
        {value: {currencyCode: "EUR", centAmount: 2000}},
        {value: {currencyCode: "EUR", centAmount: 2100}, country: "US"},
        {value: {currencyCode: "EUR", centAmount: 2200}, customerGroup: {id: "59c64f80-6472-474e-b5be-dc57b45b2faf", typeId: "customer-group"}}
      ]
    }
  ]

NEW_PRODUCT =
  id: "123"
  name:
    en: "Foo"
    it: "Boo"
  slug:
    en: "foo"
    it: "boo"
  masterVariant:
    id: 1
    prices: [
      {value: {currencyCode: "EUR", centAmount: 100}},
      {value: {currencyCode: "EUR", centAmount: 3800}}, # change
      {value: {currencyCode: "EUR", centAmount: 1100}, country: "IT"} # change
    ]
  variants: [
    {
      id: 2
      prices: [
        {value: {currencyCode: "EUR", centAmount: 100}},
        {value: {currencyCode: "EUR", centAmount: 2000}},
        {value: {currencyCode: "EUR", centAmount: 2200}, customerGroup: {id: "59c64f80-6472-474e-b5be-dc57b45b2faf", typeId: "customer-group"}}
      ]
    }
  ]

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

  it "should return reference to the object", ->
    s = @sync.buildActions(NEW_PRODUCT, OLD_PRODUCT)
    expect(s).toEqual @sync

  it "should build the action update", ->
    update = @sync.buildActions(NEW_PRODUCT, OLD_PRODUCT).get()
    expected_update =
      actions: [
        { action: "changeName", name: {en: "Foo", de: undefined, it: "Boo"} }
        { action: "changeSlug", slug: {en: "foo", it: "boo"} }
        { action: "setDescription", description: undefined }
        { action: "removePrice", variantId: 1, price: {value: {currencyCode: "EUR", centAmount: 1000}} }
        { action: "removePrice", variantId: 1, price: {value: {currencyCode: "EUR", centAmount: 1100}, country: "DE"} }
        { action: "removePrice", variantId: 1, price: {value: {currencyCode: "EUR", centAmount: 1200}, customerGroup: {id: "984a64de-24a4-42c0-868b-da7abfe1c5f6", typeId: "customer-group"}} }
        { action: "removePrice", variantId: 2, price: {value: {currencyCode: "EUR", centAmount: 2100}, country: "US"} }
        { action: "removePrice", variantId: 2, price: {value: {currencyCode: "EUR", centAmount: 2200}, customerGroup: {id: "59c64f80-6472-474e-b5be-dc57b45b2faf", typeId: "customer-group"}} }
        { action: "addPrice", variantId: 1, price: {value: {currencyCode: "EUR", centAmount: 3800}} }
        { action: "addPrice", variantId: 1, price: {value: {currencyCode: "EUR", centAmount: 1100}, country: "IT"} }
        { action: "addPrice", variantId: 2, price: {value: {currencyCode: "EUR", centAmount: 2200}, customerGroup: {id: "59c64f80-6472-474e-b5be-dc57b45b2faf", typeId: "customer-group"}} }
      ]
      version: OLD_PRODUCT.version
    expect(update).toEqual expected_update


describe "Sync.get", ->

  beforeEach ->
    @sync = new Sync
    @sync._data =
      update: "a"
      updateId: "123"

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
    spyOn(@sync._rest, "POST").andCallFake((path, payload, callback)-> callback(null, null, {id: "123"}))
    @sync._data =
      update:
        actions: []
        version: 1
      updateId: "123"
    callMe = (e, r, b)->
      expect(b.id).toBe "123"
      done()
    @sync.update(callMe)
    expect(@sync._rest.POST).toHaveBeenCalledWith("/products/123", JSON.stringify(@sync._data.update), jasmine.any(Function))

  it "should return '304' if there are no update actions", (done)->
    spyOn(@sync._rest, "POST")
    callMe = (e, r, b)->
      expect(e).toBe null
      expect(r.statusCode).toBe 304
      expect(b).toBe null
      done()
    @sync.update(callMe)
    expect(@sync._rest.POST).not.toHaveBeenCalled()
