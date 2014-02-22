_ = require("underscore")._
Q = require("q")
{Rest, OAuth2, Logger} = require("sphere-node-connect")
SphereClient = require 'sphere-node-client'
ProductSync = require("../../lib/sync/product-sync")
Config = require('../../config').config
product = require("../../models/product.json")

# Increase timeout
jasmine.getEnv().defaultTimeoutInterval = 10000

describe "Integration test", ->

  beforeEach (done) ->
    @sync = new ProductSync config: Config.prod
    @sphereClient = new SphereClient config: Config.prod

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

    @sphereClient.productTypes.save(pt).then (productType) =>
      @newProduct.productType.id = productType.id
      @sphereClient.products.save(@newProduct).then (product) =>
        @oldProduct = product.masterData.staged
        @oldProduct.productType = product.productType # set product type to staged subset
        # set id for matching and version for update
        @oldProduct.id = product.id
        @oldProduct.version = product.version
        @newProduct.id = product.id
        done()

    .fail (msg) ->
      console.log msg
      expect(true).toBe false
      done()


  it 'should not update minimum product', (done) ->
    data = @sync.buildActions @newProduct, @oldProduct
    data.update (e, r, b) ->
      expect(r.statusCode).toBe 304
      done()

  it 'should update name', (done) ->
    @newProduct.name.en = "Hello"
    @newProduct.name.de = "Hallo"
    data = @sync.buildActions @newProduct, @oldProduct
    data.update (e, r, b) ->
      expect(r.statusCode).toBe 200
      expect(b.masterData.staged.name.en).toBe "Hello"
      expect(b.masterData.staged.name.de).toBe "Hallo"
      done()

  it 'should add, update and delete tax category', (done) ->
    tax =
      name: "myTax-#{@unique}"
      rates: []

    # addition
    @sphereClient.taxCategories.save(tax).then (taxCategory) =>
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
        @sphereClient.taxCategories.save(tax).then (taxCategory2) =>
          @newProduct.taxCategory.id = taxCategory2.id

          # TODO: provide method to extract compare data from products endpoint
          @oldProduct = b.masterData.staged
          @oldProduct.productType = b.productType # set product type to staged subset
          # set id for matching and version for update
          @oldProduct.id = b.id
          @oldProduct.version = b.version

          data = @sync.buildActions @newProduct, @oldProduct
          data.update (e, r, b) =>
            expect(r.statusCode).toBe 200
            expect(b.taxCategory).toBeDefined()
            expect(b.taxCategory.typeId).toBe 'tax-category'
            expect(b.taxCategory.id).toBe taxCategory2.id

    # deletion
            @newProduct.taxCategory = null
            @oldProduct.version = b.version

            data = @sync.buildActions @newProduct, @oldProduct
            data.update (e, r, b) ->
              expect(r.statusCode).toBe 200
              expect(b.taxCategory).toBeUndefined()
              done()

    .fail (msg) ->
      console.log msg
      expect(true).toBe false
      done()


describe "Integration test between projects", ->

  beforeEach (done) ->
    @logger = new Logger()
    getAuthToken = (config) ->
      d = Q.defer()
      oa = new OAuth2 config: config
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
      @restStaging = new Rest config: staging
      @restProd = new Rest config: prod
      @sync = new ProductSync config: staging
      done()
    ).fail (err) -> throw new Error(err)

  afterEach ->
    @restStaging = null
    @restProd = null
    @sync = null

  it "should sync products with same SKU", (done) ->
    triggerFail = (e)=>
      @logger.error e
      done('Error when syncing SKU (see ./sphere-node-connect-debug.log)')

    getProducts = (rest) ->
      deferred = Q.defer()
      rest.GET "/product-projections?staged=true", (error, response, body) ->
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

    getProducts(@restProd).then((products)=>
      # sync prod -> staging
      searches = _.map products, (prodProd)=>
        sku = prodProd.masterVariant.sku
        searchProduct(@restStaging, sku, prodProd)
      # 'allSettled' waits for all of the promises to either be fulfilled or rejected
      Q.allSettled searches
    ).then((responses)=>
      updates = []
      _.each responses, (response)=>
        # 'results' is an array of result objects like
        # {state: "fulfilled", value: resolvedValue}
        # {state: "rejected", reason: rejectedError}
        if response.state is "fulfilled"
          resolver = response.value
          stagingProd = _.first(resolver.results)
          # sync only if product is found on staging
          if stagingProd
            updates.push syncProducts(@sync, resolver.product, stagingProd)
      Q.allSettled updates
    ).then((results) ->
      errors = []
      _.each results, (result) ->
        if result.state is "fulfilled"
          expect(result.value).toBe true
        else
          errors.push result.reason
      if errors.length > 0
        triggerFail errors
        done()
      else
        done()
    ).fail (err) ->
      console.log "Error: %j", errors
      triggerFail [err]
