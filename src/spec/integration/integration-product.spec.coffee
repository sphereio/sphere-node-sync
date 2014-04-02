_ = require 'underscore'
Q = require 'q'
Logger = require '../../lib/logger'
ProductSync = require '../../lib/sync/product-sync'
Config = require('../../config').config
product = require '../../models/product.json'

# Increase timeout
jasmine.getEnv().defaultTimeoutInterval = 10000

getProductFromStaged = (product) ->
  p = product.masterData.staged
  # set product type to staged subset
  p.productType = product.productType
  # set id for matching and version for update
  p.id = product.id
  p.version = product.version
  p

describe 'Integration test', ->

  beforeEach (done) ->
    @sync = new ProductSync
      config: Config.prod
      logConfig:
        levelStream: 'error'
        levelFile: 'error'
    @client = @sync._client

    @unique = new Date().getTime()
    pt =
      name: 'myType'
      description: 'foo'
    @newProduct =
      name:
        en: 'Foo'
      slug:
        en: "foo-#{@unique}"
      productType:
        typeId: 'product-type'
      # without all these default the syncer does not work!
      categories: []
      masterVariant:
        id: 1
        attributes: []
        prices: []
        images: []

    @client.productTypes.save(pt)
    .then (result) =>
      @newProduct.productType.id = result.body.id
      @client.products.save(@newProduct)
    .then (result) =>
      product = result.body
      @oldProduct = product.masterData.staged
      @oldProduct.productType = product.productType # set product type to staged subset
      # set id for matching and version for update
      @oldProduct.id = product.id
      @oldProduct.version = product.version
      @newProduct.id = product.id
      done()
    .fail (msg) -> done(msg)


  it 'should not update minimum product', (done) ->
    data = @sync.buildActions @newProduct, @oldProduct
    data.update()
    .then (result) ->
      expect(result.statusCode).toBe 304
      done()
    .fail (error) -> done(error)

  it 'should update name', (done) ->
    @newProduct.name.en = 'Hello'
    @newProduct.name.de = 'Hallo'
    data = @sync.buildActions @newProduct, @oldProduct
    data.update()
    .then (result) ->
      expect(result.statusCode).toBe 200
      expect(result.body.masterData.staged.name.en).toBe 'Hello'
      expect(result.body.masterData.staged.name.de).toBe 'Hallo'
      done()
    .fail (error) -> done(error)

  it 'should add, update and delete tax category', (done) ->
    tax =
      name: "myTax-#{@unique}"
      rates: []

    # addition
    @client.taxCategories.save(tax)
    .then (result) =>
      @taxCategory = result.body
      @newProduct.taxCategory =
        typeId: 'tax-category'
        id: @taxCategory.id
      data = @sync.buildActions @newProduct, @oldProduct
      data.update()
    .then (result) =>
      @productResult = result.body
      expect(result.statusCode).toBe 200
      expect(result.body.taxCategory).toBeDefined()
      expect(result.body.taxCategory.typeId).toBe 'tax-category'
      expect(result.body.taxCategory.id).toBe @taxCategory.id

    # change
      tax =
        name: "myTax2-#{@unique}"
        rates: []
      @client.taxCategories.save(tax)
    .then (result) =>
      @taxCategory2 = result.body
      @newProduct.taxCategory.id = @taxCategory2.id
      @oldProduct = getProductFromStaged @productResult
      data = @sync.buildActions @newProduct, @oldProduct
      data.update()
    .then (result) =>
      expect(result.statusCode).toBe 200
      expect(result.body.taxCategory).toBeDefined()
      expect(result.body.taxCategory.typeId).toBe 'tax-category'
      expect(result.body.taxCategory.id).toBe @taxCategory2.id

    # deletion
      @oldProduct = getProductFromStaged result.body
      @newProduct.taxCategory = null

      data = @sync.buildActions @newProduct, @oldProduct
      data.update()
    .then (result) ->
      expect(result.statusCode).toBe 200
      expect(result.body.taxCategory).not.toBeDefined()
      done()
    .fail (msg) -> done(msg)

  it 'should add, change and remove image', (done) ->
    @newProduct.masterVariant.images = [
      { url: '//example.com/image.png', dimensions: { h: 0, w: 0 } }
    ]

    # addition
    data = @sync.buildActions @newProduct, @oldProduct
    data.update()
    .then (result) =>
      product = result.body
      expect(result.statusCode).toBe 200
      expect(_.size product.masterData.staged.masterVariant.images).toBe 1
      expect(product.masterData.staged.masterVariant.images[0].url).toBe '//example.com/image.png'

    # change
      @oldProduct = getProductFromStaged product
      @newProduct.masterVariant.images = [
        { url: '//example.com/CHANGED.png', dimensions: { h: 0, w: 0 } }
      ]
      data = @sync.buildActions @newProduct, @oldProduct
      data.update()
    .then (result) =>
      product = result.body
      expect(result.statusCode).toBe 200
      expect(_.size product.masterData.staged.masterVariant.images).toBe 1
      expect(product.masterData.staged.masterVariant.images[0].url).toBe '//example.com/CHANGED.png'

    # deletion
      @oldProduct = getProductFromStaged product
      @newProduct.masterVariant.images = []
      data = @sync.buildActions @newProduct, @oldProduct
      data.update()
    .then (result) ->
      expect(result.statusCode).toBe 200
      expect(_.size result.body.masterData.staged.masterVariant.images).toBe 0
      done()
    .fail (msg) -> done(JSON.stringify(msg))

describe 'Integration test between projects', ->

  beforeEach ->
    logger = new Logger
      levelStream: 'error'
      levelFile: 'error'

    @syncStaging = new ProductSync
      config: Config.staging
      logConfig:
        levelStream: 'error'
        levelFile: 'error'
    @syncProd = new ProductSync
      config: Config.prod
      logConfig:
        levelStream: 'error'
        levelFile: 'error'

  it 'should sync products with same SKU', (done) ->

    @syncProd._client.productProjections.staged(true).fetch()
    .then (result) =>
      @allProdProducts = result.body.results
      # sync prod -> staging
      searches = _.filter @allProdProducts, (prodProd) -> prodProd.masterVariant.sku
      .map (prodProd) =>
        sku = prodProd.masterVariant.sku
        predicate = "masterVariant(sku=\"#{sku}\")"
        @syncStaging._client.productProjections.where(predicate).staged(true).fetch()

      # 'allSettled' waits for all of the promises to either be fulfilled or rejected
      Q.allSettled searches
    .then (responses) =>
      updates = []
      _.each responses, (response) =>
        # 'results' is an array of result objects like
        # {state: "fulfilled", value: resolvedValue}
        # {state: "rejected", reason: rejectedError}
        if response.state is 'fulfilled'
          resolver = response.value
          stagingProd = _.first(resolver.body.results)
          # sync only if product is found on staging
          if stagingProd
            prodProd = _.find @allProdProducts, (p) -> p.masterVariant.sku is stagingProd.masterVariant.sku
            updates.push @syncStaging.buildActions(prodProd, stagingProd).update()
      Q.allSettled updates
    .then (results) ->
      errors = []
      _.each results, (result) ->
        if result.state is 'fulfilled'
          expect(result.value.statusCode).toBe (200 or 304)
        else
          errors.push result.reason
      if errors.length > 0
        done(JSON.stringify(errors))
      else
        done()
    .fail (err) -> done(JSON.stringify(err))
