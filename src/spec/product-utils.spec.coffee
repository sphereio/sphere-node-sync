ProductUtils = require("../lib/product-utils")

###
Match different product attributes and variant prices
###
OLD_PRODUCT =
  id: "123"
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

###
Match all different attributes types
###
OLD_ALL_ATTRIBUTES =
  id: "123"
  masterVariant:
    id: 1
    attributes: [
      { name: "foo", value: "bar" } # text
      { name: "dog", value: {en: "Dog", de: "Hund"} } # ltext
      { name: "num", value: 50 } # number
      { name: "count", value: { label: "One", key: "one" } } # enum
      { name: "size", value: { label: {en: "Size"}, key: "medium" } } # lenum
      { name: "color", value: { label: {en: "Color"}, key: "red" } } # lenum
      { name: "cost", value: { centAmount: 990, currencyCode: "EUR" } } # money
    ]
NEW_ALL_ATTRIBUTES =
  id: "123"
  masterVariant:
    id: 1
    attributes: [
      { name: "foo", value: "qux" } # text
      { name: "dog", value: {en: "Doggy", it: "Cane"} } # ltext
      { name: "num", value: 100 } # number
      { name: "count", value: { label: "Two", key: "two" } } # enum
      { name: "size", value: { label: {de: "Größe"}, key: "small" } } # lenum
      { name: "color", value: { label: {en: "Color"}, key: "blue" } } # lenum
      { name: "cost", value: { centAmount: 550, currencyCode: "EUR" } } # money
    ]

###
Match different attributes on variant level
###
OLD_ATTRIBUTES =
  id: "123"
  masterVariant:
    id: 1
    attributes: [
      { name:"uid", value: "20063672" },
      { name:"length", value: 160 },
      { name:"wide", value: 85 },
      { name:"bulkygoods", value: { label:"Ja", key:"YES" } },
      { name:"ean", value: "20063672" }
    ]
  variants: [
    {
      id: 2
      attributes: [
        { name:"uid", value: "20063672" },
        { name:"length", value: 160 },
        { name:"wide", value: 85 },
        { name:"bulkygoods", value: { label:"Ja", key:"YES" } },
        { name:"ean", value: "20063672" }
      ]
    },
    {
      id: 3
      attributes: []
    }
    {
      id: 4
      attributes: [
        { name:"uid", value: "1234567" },
        { name:"length", value: 123 },
        { name:"bulkygoods", value: { label: "Si", key: "SI" } }
      ]
    }
  ]
NEW_ATTRIBUTES =
  id: "123"
  masterVariant:
    id: 1
    attributes: [
      { name:"uid", value: "20063675" },
      { name:"length", value: 160 },
      { name:"wide", value: 10 },
      { name:"bulkygoods", value: { label: "Nein", key: "NO" } },
      { name:"ean", value: "20063672" }
    ]
  variants: [
    {
      id: 2
      attributes: [
        { name:"uid", value: "20055572" },
        { name:"length", value: 333 },
        { name:"wide", value: 33 },
        { name:"bulkygoods", value: { label: "Ja", key: "YES" } },
        { name:"ean", value: "20063672" }
      ]
    },
    {
      id: 3
      attributes: [
        { name:"uid", value: "00001" },
        { name:"length", value: 500 },
        { name:"bulkygoods", value: { label: "Si", key: "SI" } }
      ]
    },
    {
      id: 4
      attributes: []
    }
  ]

describe "ProductUtils.diff", ->
  beforeEach ->
    @utils = new ProductUtils

  it "should diff nothing", ->
    delta = @utils.diff({id: "123"}, {id: "123"})
    expect(delta).not.toBeDefined()

  it "should diff basic attributes (name, slug, description)", ->
    OLD =
      id: "123"
      name:
        en: "Foo"
        de: "Hoo"
      slug:
        en: "foo"
      description:
        en: "Sample"
    NEW =
      id: "123"
      name:
        en: "Boo"
      slug:
        en: "boo"
      description:
        en: "Sample"
        it: "Esempio"

    delta = @utils.diff(OLD, NEW)
    expected_delta =
      name:
        en: ["Foo", "Boo"]
        de: ["Hoo", 0, 0 ]
      slug:
        en: ["foo", "boo"]
      description:
        it: ["Esempio"]
    expect(delta).toEqual expected_delta

  it "should diff missing attribute", ->
    delta = @utils.diff(OLD_PRODUCT, NEW_PRODUCT)
    expected_delta =
      name:
        en: ["SAPPHIRE", "Foo"] # changed
        de: ["Hoo", 0, 0 ]
        it: ["Boo"]
      slug:
        en: ["sapphire1366126441922", "foo"]
        it: ["boo"]
      description: [en: "Sample description", 0, 0] # deleted
      masterVariant:
        prices:
          1: { value:{ centAmount:[ 1000, 3800 ] } }
          2: { country:['DE', 'IT'] }
          _t:'a'
          _3:[{value:{currencyCode:'EUR', centAmount:1200 }, customerGroup:{id:'984a64de-24a4-42c0-868b-da7abfe1c5f6', typeId:'customer-group'}, _id:3}, 0, 0]
      variants:
        0:
          prices:
            2:
              value:{ centAmount:[ 2100, 2200 ] },
              customerGroup:[{id:'59c64f80-6472-474e-b5be-dc57b45b2faf', typeId:'customer-group'}],
              country:['US', 0, 0]
            _t:'a'
            _3:[{value:{currencyCode:'EUR', centAmount:2200 }, customerGroup:{id:'59c64f80-6472-474e-b5be-dc57b45b2faf', typeId:'customer-group'}, _id:3}, 0, 0]
        _t:'a'
    expect(delta).toEqual expected_delta

  it "should diff different attribute types", ->
    delta = @utils.diff(OLD_ALL_ATTRIBUTES, NEW_ALL_ATTRIBUTES)
    expected_delta =
      masterVariant:
        attributes:
          0: { value: ["bar", "qux"] }
          1:
            value:
              en: ["Dog", "Doggy"]
              it: ["Cane"]
              de: ["Hund", 0, 0]
          2: { value: [50, 100] }
          3: { value: { label: ["One", "Two"], key: ["one", "two"] } }
          4:
            value:
              label:
                de: ["Größe"]
                en: ["Size", 0, 0]
              key: ["medium", "small"]
          5: { value: { key: ["red", "blue"] } }
          6: { value: { centAmount : [990, 550] } }
          _t : "a"

    expect(delta).toEqual expected_delta


describe "ProductUtils.actionsMapAttributes", ->
  beforeEach ->
    @utils = new ProductUtils

  it "should build attribute actions", ->
    delta = @utils.diff(OLD_ATTRIBUTES, NEW_ATTRIBUTES)
    expected_delta =
      masterVariant:
        attributes:
          0: { value: ["20063672", "20063675"] }
          2: { value: [85, 10] }
          3: { value: { label: ["Ja", "Nein"], key: ["YES", "NO"] } }
          _t: "a"
      variants:
        0:
          attributes:
            0: { value: ["20063672", "20055572"] }
            1: { value: [160, 333] }
            2: { value: [85, 33] }
            _t: "a"
        1:
          attributes:
            0: [ { name: "uid", value: "00001" } ]
            1: [ { name: "length", value: 500 } ]
            2: [ { name: "bulkygoods", value: { label: "Si", key: "SI"} } ]
            _t: "a"
        2:
          attributes:
            _t: "a"
            _0: [ { name: "uid", value: "1234567" }, 0, 0 ]
            _1: [ { name: "length", value: 123 }, 0, 0 ]
            _2: [ { name: "bulkygoods", value: { label: "Si", key: "SI" } }, 0, 0 ]
        _t: "a"
    expect(delta).toEqual expected_delta

    update = @utils.actionsMapAttributes(delta, NEW_ATTRIBUTES)
    expected_update =
      [
        { action: "setAttribute", variantId: 1, name: "uid", value: "20063675" }
        { action: "setAttribute", variantId: 1, name: "wide", value: 10 }
        { action: "setAttribute", variantId: 1, name: "bulkygoods", value:{ label:"Nein", key:"NO" } }
        { action: "setAttribute", variantId: 2, name: "uid", value: "20055572" }
        { action: "setAttribute", variantId: 2, name: "length", value: 333 }
        { action: "setAttribute", variantId: 2, name: "wide", value: 33 }
        { action: "setAttribute", variantId: 3, name: "uid", value: "00001" }
        { action: "setAttribute", variantId: 3, name: "length", value: 500 }
        { action: "setAttribute", variantId: 3, name: "bulkygoods", value: { label:"Si", key:"SI" } }
        { action: "setAttribute", variantId: 4, name: "uid", value: undefined }
        { action: "setAttribute", variantId: 4, name: "length", value: undefined }
        { action: "setAttribute", variantId: 4, name: "bulkygoods", value: undefined }
      ]
    expect(update).toEqual expected_update

  it "should build attribute actions for all types", ->
    delta = @utils.diff(OLD_ALL_ATTRIBUTES, NEW_ALL_ATTRIBUTES)
    update = @utils.actionsMapAttributes(delta, NEW_ALL_ATTRIBUTES)
    expected_update =
      [
        { action: "setAttribute", variantId: 1, name: "foo", value: "qux" }
        { action: "setAttribute", variantId: 1, name: "dog", value: {en: "Doggy", it: "Cane", de : undefined} }
        { action: "setAttribute", variantId: 1, name: "num", value: 100 }
        { action: "setAttribute", variantId: 1, name: "count", value: { label: "Two", key: "two" } }
        { action: "setAttribute", variantId: 1, name: "size", value: { label: {de: "Größe", en : undefined}, key: "small" } }
        { action: "setAttribute", variantId: 1, name: "color", value: { label: {en : "Color"}, key: "blue" } }
        { action: "setAttribute", variantId: 1, name: "cost", value: { centAmount: 550, currencyCode: "EUR" } }
      ]
    expect(update).toEqual expected_update
