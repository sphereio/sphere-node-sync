_ = require('underscore')._
Q = require 'q'
{Rest, OAuth2, Logger} = require 'sphere-node-connect'
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

  createResourcePromise = (rest, url, body) ->
    deferred = Q.defer()
    rest.POST url, JSON.stringify(body), (error, response, body) ->
      if response.statusCode is 201
        deferred.resolve body
      else if error
        deferred.reject new Error(error)
      else
        deferred.reject new Error(body)
    deferred.promise

  beforeEach (done) ->
    @sync = new ProductSync
      config: Config.prod
      logConfig:
        levelStream: 'error'
        levelFile: 'error'
    @rest = @sync._rest

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

    createResourcePromise(@rest, '/product-types', pt)
    .then (productType) =>
      @newProduct.productType.id = productType.id
      createResourcePromise(@rest, '/products', @newProduct)
    .then (product) =>
      @oldProduct = product.masterData.staged
      @oldProduct.productType = product.productType # set product type to staged subset
      # set id for matching and version for update
      @oldProduct.id = product.id
      @oldProduct.version = product.version
      @newProduct.id = product.id
      done()
    .fail (msg) ->
      done(msg)


  it 'should not update minimum product', (done) ->
    data = @sync.buildActions @newProduct, @oldProduct
    data.update (e, r, b) ->
      expect(r.statusCode).toBe 304
      done()

  it 'should update name', (done) ->
    @newProduct.name.en = 'Hello'
    @newProduct.name.de = 'Hallo'
    data = @sync.buildActions @newProduct, @oldProduct
    data.update (e, r, b) ->
      expect(r.statusCode).toBe 200
      expect(b.masterData.staged.name.en).toBe 'Hello'
      expect(b.masterData.staged.name.de).toBe 'Hallo'
      done()

  it 'should add, update and delete tax category', (done) ->
    tax =
      name: "myTax-#{@unique}"
      rates: []

    # addition
    createResourcePromise(@rest, '/tax-categories', tax)
    .then (taxCategory) =>
      @newProduct.taxCategory =
        typeId: 'tax-category'
        id: taxCategory.id
      data = @sync.buildActions @newProduct, @oldProduct
      data.update (e, r, b) =>
        expect(r.statusCode).toBe 200
        expect(b.taxCategory).toBeDefined()
        expect(b.taxCategory.typeId).toBe 'tax-category'
        expect(b.taxCategory.id).toBe taxCategory.id

    # change
        tax =
          name: "myTax2-#{@unique}"
          rates: []
        createResourcePromise(@rest, '/tax-categories', tax)
        .then (taxCategory2) =>
          @newProduct.taxCategory.id = taxCategory2.id
          @oldProduct = getProductFromStaged b
          data = @sync.buildActions @newProduct, @oldProduct
          data.update (e, r, b) =>
            expect(r.statusCode).toBe 200
            expect(b.taxCategory).toBeDefined()
            expect(b.taxCategory.typeId).toBe 'tax-category'
            expect(b.taxCategory.id).toBe taxCategory2.id

    # deletion
            @oldProduct = getProductFromStaged b
            @newProduct.taxCategory = null

            data = @sync.buildActions @newProduct, @oldProduct
            data.update (e, r, b) ->
              expect(r.statusCode).toBe 200
              expect(b.taxCategory).toBeUndefined()
              done()
        .fail (msg) ->
          done(msg)
    .fail (msg) ->
      done(msg)

  it 'should add, change and remove image', (done) ->
    @newProduct.masterVariant.images = [
      { url: '//example.com/image.png', dimensions: { h: 0, w: 0 } }
    ]

    # addition
    data = @sync.buildActions @newProduct, @oldProduct
    data.update (e, r, b) =>
      expect(r.statusCode).toBe 200
      expect(_.size b.masterData.staged.masterVariant.images).toBe 1
      expect(b.masterData.staged.masterVariant.images[0].url).toBe '//example.com/image.png'

    # change
      @oldProduct = getProductFromStaged b
      @newProduct.masterVariant.images = [
        { url: '//example.com/CHANGED.png', dimensions: { h: 0, w: 0 } }
      ]
      data = @sync.buildActions @newProduct, @oldProduct
      data.update (e, r, b) =>
        expect(r.statusCode).toBe 200
        expect(_.size b.masterData.staged.masterVariant.images).toBe 1
        expect(b.masterData.staged.masterVariant.images[0].url).toBe '//example.com/CHANGED.png'

    # deletion
        @oldProduct = getProductFromStaged b
        @newProduct.masterVariant.images = []
        data = @sync.buildActions @newProduct, @oldProduct
        data.update (e, r, b) ->
          expect(r.statusCode).toBe 200
          expect(_.size b.masterData.staged.masterVariant.images).toBe 0
          done()

describe 'Integration test between projects', ->

  beforeEach (done) ->
    getAuthToken = (config) ->
      d = Q.defer()
      oa = new OAuth2
        config: config
        logConfig:
          levelStream: 'error'
          levelFile: 'error'
      oa.getAccessToken (error, response, body) ->
        if body
          optionsApi = _.clone(config)
          optionsApi.access_token = body.access_token
          d.resolve(optionsApi)
        else
          d.reject new Error(error)
      d.promise

    allAuthTokens = Q.all [getAuthToken(Config.staging), getAuthToken(Config.prod)]
    allAuthTokens.spread((staging, prod)=>
      @restStaging = new Rest
        config: staging
        logConfig:
          levelStream: 'error'
          levelFile: 'error'
      @restProd = new Rest
        config: prod
        logConfig:
          levelStream: 'error'
          levelFile: 'error'
      @sync = new ProductSync
        config: staging
        logConfig:
          levelStream: 'error'
          levelFile: 'error'
      done()
    ).fail (err) -> done(err)

  afterEach ->
    @restStaging = null
    @restProd = null
    @sync = null

  it 'should sync products with same SKU', (done) ->

    getProducts = (rest) ->
      deferred = Q.defer()
      rest.GET '/product-projections?staged=true', (error, response, body) ->
        if response.statusCode is 200
          deferred.resolve body.results
        else
          deferred.reject body
      deferred.promise

    searchProduct = (rest, value, prod) ->
      deferred = Q.defer()
      predicate = "masterVariant(sku=\"#{value}\")"
      rest.GET "/product-projections?where=#{encodeURIComponent(predicate)}&staged=true", (error, response, body) ->
        if response.statusCode is 200
          deferred.resolve
            product: prod
            results: body.results
        else
          deferred.reject body
      deferred.promise

    syncProducts = (sync, new_product, old_product) ->
      new_product.categories = [] # categories can not be transformed by Id to another project.
      deferred = Q.defer()
      try
        sync.buildActions(new_product, old_product).update (e, r, b) ->
          if r.statusCode is 200 or r.statusCode is 304
            deferred.resolve(true)
          else
            deferred.reject b
      catch e
        deferred.reject e
      deferred.promise

    getProducts(@restProd)
    .then (products) =>
      # sync prod -> staging
      searches = _.map products, (prodProd) =>
        sku = prodProd.masterVariant.sku
        searchProduct(@restStaging, sku, prodProd)
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
          stagingProd = _.first(resolver.results)
          # sync only if product is found on staging
          if stagingProd
            updates.push syncProducts(@sync, resolver.product, stagingProd)
      Q.allSettled updates
    .then (results) ->
      errors = []
      _.each results, (result) ->
        if result.state is 'fulfilled'
          expect(result.value).toBe true
        else
          errors.push result.reason
      if errors.length > 0
        done(errors)
      else
        done()
    .fail (err) ->
      done(err)
