_ = require 'underscore'
ProductSync = require '../../lib/sync/product-sync'
Config = require('../../config').config.prod

OLD_PRODUCT =
  id: '123'
  version: 1
  name:
    en: 'SAPPHIRE'
    de: 'Hoo'
  slug:
    en: 'sapphire1366126441922'
  description:
    en: 'Sample description'
  masterVariant:
    id: 1
    prices: [
      {value: {currencyCode: 'EUR', centAmount: 100}},
      {value: {currencyCode: 'EUR', centAmount: 1000}},
      {value: {currencyCode: 'EUR', centAmount: 1100}, country: 'DE'},
      {value: {currencyCode: 'EUR', centAmount: 1200}, customerGroup: {id: '984a64de-24a4-42c0-868b-da7abfe1c5f6', typeId: 'customer-group'}}
    ]
  variants: [
    {
      id: 2
      prices: [
        {value: {currencyCode: 'EUR', centAmount: 100}},
        {value: {currencyCode: 'EUR', centAmount: 2000}},
        {value: {currencyCode: 'EUR', centAmount: 2100}, country: 'US'},
        {value: {currencyCode: 'EUR', centAmount: 2200}, customerGroup: {id: '59c64f80-6472-474e-b5be-dc57b45b2faf', typeId: 'customer-group'}}
      ]
    }
    { id: 4 }
    {
      id: 77
      prices: [
        {value: {currencyCode: 'EUR', centAmount: 5889}, country: 'DE'},
        {value: {currencyCode: 'EUR', centAmount: 5889}, country: 'AT'},
        {value: {currencyCode: 'EUR', centAmount: 6559}, country: 'FR'},
        {value: {currencyCode: 'EUR', centAmount: 13118}, country: 'BE'}
      ]
    }
  ]

NEW_PRODUCT =
  id: '123'
  name:
    en: 'Foo'
    it: 'Boo'
  slug:
    en: 'foo'
    it: 'boo'
  masterVariant:
    id: 1
    prices: [
      {value: {currencyCode: 'EUR', centAmount: 100}},
      {value: {currencyCode: 'EUR', centAmount: 3800}}, # change
      {value: {currencyCode: 'EUR', centAmount: 1100}, country: 'IT'} # change
    ]
  variants: [
    {
      id: 2
      prices: [
        {value: {currencyCode: 'EUR', centAmount: 100}},
        {value: {currencyCode: 'EUR', centAmount: 2000}},
        {value: {currencyCode: 'EUR', centAmount: 2200}, customerGroup: {id: '59c64f80-6472-474e-b5be-dc57b45b2faf', typeId: 'customer-group'}}
      ]
    }
    { sku: 'new', attributes: [ { name: 'what', value: 'no ID' } ] }
    { id: 7, attributes: [ { name: 'what', value: 'no SKU' } ] }
    {
      id: 77
      prices: [
        {value: {currencyCode: 'EUR', centAmount: 5889}, country: 'DE'},
        {value: {currencyCode: 'EUR', centAmount: 4790}, country: 'DE', customerGroup: {id: 'special-price-id', typeId: 'customer-group'}},
        {value: {currencyCode: 'EUR', centAmount: 5889}, country: 'AT'},
        {value: {currencyCode: 'EUR', centAmount: 4790}, country: 'AT', customerGroup: {id: 'special-price-id', typeId: 'customer-group'}},
        {value: {currencyCode: 'EUR', centAmount: 6559}, country: 'FR'},
        {value: {currencyCode: 'EUR', centAmount: 13118}, country: 'BE'}
      ]
    }
  ]

describe 'ProductSync', ->

  it 'should initialize', ->
    sync = new ProductSync
    expect(sync).toBeDefined()
    expect(sync._actions).not.toBeDefined()

  it 'should initialize with options', ->
    sync = new ProductSync
      config: Config
      logConfig:
        levelStream: 'error'
        levelFile: 'error'
    expect(sync).toBeDefined()
    expect(sync._client._rest).toBeDefined()
    expect(sync._client._rest._options.config).toEqual Config

  it 'should throw error if no credentials are given', ->
    sync = -> new ProductSync foo: 'bar'
    expect(sync).toThrow new Error('Missing credentials')

  _.each ['client_id', 'client_secret', 'project_key'], (key) ->
    it "should throw error if no '#{key}' is defined", ->
      opt = _.clone(Config)
      delete opt[key]
      sync = -> new ProductSync
        config: opt
        logConfig:
          levelStream: 'error'
          levelFile: 'error'
      expect(sync).toThrow new Error("Missing '#{key}'")


  describe ':: config', ->

    beforeEach ->
      @sync = new ProductSync

    afterEach ->
      @sync = null

    it 'should build white/black-listed actions update', ->
      opts = [
        {type: 'base', group: 'white'}
        {type: 'prices', group: 'black'}
      ]
      update = @sync.config(opts).buildActions(NEW_PRODUCT, OLD_PRODUCT).get()
      expected_update =
        actions: [
          { action: 'changeName', name: {en: 'Foo', de: undefined, it: 'Boo'} }
          { action: 'changeSlug', slug: {en: 'foo', it: 'boo'} }
          { action: 'setDescription', description: undefined }
        ]
        version: OLD_PRODUCT.version
      expect(update).toEqual expected_update


  describe ':: buildActions', ->

    beforeEach ->
      @sync = new ProductSync

    afterEach ->
      @sync = null

    it 'should build the action update', ->
      update = @sync.buildActions(NEW_PRODUCT, OLD_PRODUCT).get()
      expected_update =
        actions: [
          { action: 'changeName', name: {en: 'Foo', de: undefined, it: 'Boo'} }
          { action: 'changeSlug', slug: {en: 'foo', it: 'boo'} }
          { action: 'setDescription', description: undefined }
          { action: 'changePrice', variantId: 1, price: {value: {currencyCode: 'EUR', centAmount: 3800}} }
          { action: 'removePrice', variantId: 1, price: {value: {currencyCode: 'EUR', centAmount: 1100}, country: 'DE'} }
          { action: 'removePrice', variantId: 1, price: {value: {currencyCode: 'EUR', centAmount: 1200}, customerGroup: {id: '984a64de-24a4-42c0-868b-da7abfe1c5f6', typeId: 'customer-group'}} }
          { action: 'removePrice', variantId: 2, price: {value: {currencyCode: 'EUR', centAmount: 2100}, country: 'US'} }
          { action: 'removePrice', variantId: 2, price: {value: {currencyCode: 'EUR', centAmount: 2200}, customerGroup: {id: '59c64f80-6472-474e-b5be-dc57b45b2faf', typeId: 'customer-group'}} }
          { action: 'removePrice', variantId: 77, price: { value: { currencyCode: 'EUR', centAmount: 5889 }, country: 'AT' } }
          { action: 'removePrice', variantId: 77, price: { value: { currencyCode: 'EUR', centAmount: 6559 }, country: 'FR' } }
          { action: 'removePrice', variantId: 77, price: { value: { currencyCode: 'EUR', centAmount: 13118 }, country: 'BE' } }
          { action: 'addPrice', variantId: 1, price: {value: {currencyCode: 'EUR', centAmount: 1100}, country: 'IT'} }
          { action: 'addPrice', variantId: 2, price: {value: {currencyCode: 'EUR', centAmount: 2200}, customerGroup: {id: '59c64f80-6472-474e-b5be-dc57b45b2faf', typeId: 'customer-group'}} }
          { action: 'addPrice', variantId: 77, price: { value: { currencyCode: 'EUR', centAmount: 4790 }, country: 'DE', customerGroup: { id: 'special-price-id', typeId: 'customer-group' } } }
          { action: 'addPrice', variantId: 77, price: { value: { currencyCode: 'EUR', centAmount: 5889 }, country: 'AT' } }
          { action: 'addPrice', variantId: 77, price: { value: { currencyCode: 'EUR', centAmount: 4790 }, country: 'AT', customerGroup: { id: 'special-price-id', typeId: 'customer-group' } } }
          { action: 'addPrice', variantId: 77, price: { value: { currencyCode: 'EUR', centAmount: 6559 }, country: 'FR' } }
          { action: 'addPrice', variantId: 77, price: { value: { currencyCode: 'EUR', centAmount: 13118 }, country: 'BE' } }
          { action: 'removeVariant', id: 4 }
          { action: 'addVariant', sku: 'new', attributes: [ { name: 'what', value: 'no ID' } ] }
          { action: 'addVariant', attributes: [ { name: 'what', value: 'no SKU' } ] }
        ]
        version: OLD_PRODUCT.version
      expect(update).toEqual expected_update

    it 'should handle mapping actions for new variants without ids', ->
      oldProduct =
        id: '123'
        version: 1
        masterVariant:
          id: 1
          sku: 'v1'
          attributes: [{name: 'foo', value: 'bar'}]
        variants: [
          { id: 2, sku: 'v2', attributes: [{name: 'foo', value: 'qux'}] }
          { id: 3, sku: 'v3', attributes: [{name: 'foo', value: 'baz'}] }
        ]

      newProduct =
        id: '123'
        masterVariant:
          sku: 'v1'
          attributes: [{name: 'foo', value: 'new value'}]
        variants: [
          { id: 2, sku: 'v2', attributes: [{name: 'foo', value: 'another value'}] }
          { id: 3, sku: 'v4', attributes: [{name: 'foo', value: 'i dont care'}] }
          { id: 4, sku: 'v3', attributes: [{name: 'foo', value: 'yet another'}] }
        ]
      update = @sync.buildActions(newProduct, oldProduct).get()
      expected_update =
        actions: [
          { action: 'setAttribute', variantId: 1, name: 'foo', value: 'new value' }
          { action: 'setAttribute', variantId: 2, name: 'foo', value: 'another value' }
          { action: 'setAttribute', variantId: 3, name: 'foo', value: 'yet another' }
          { action: 'addVariant', sku: 'v4', attributes: [{ name: 'foo', value: 'i dont care' }] }
        ]
        version: oldProduct.version
      expect(update).toEqual expected_update

  describe ':: update', ->

    beforeEach ->
      @sync = new ProductSync
        config: Config
        logConfig:
          levelStream: 'error'
          levelFile: 'error'

    afterEach ->
      @sync = null

    it 'should send update request', (done) ->
      spyOn(@sync._client._rest, 'POST').andCallFake((path, payload, callback) -> callback(null, {statusCode: 200}, {id: '123'}))
      @sync._data =
        update:
          actions: []
          version: 1
        updateId: '123'
      @sync.update()
      .then (result) =>
        expect(result.statusCode).toBe 200
        expect(result.body.id).toBe '123'
        expect(@sync._client._rest.POST).toHaveBeenCalledWith('/products/123', @sync._data.update, jasmine.any(Function))
        done()
      .fail (error) -> done(error)
