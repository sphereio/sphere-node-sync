_ = require("underscore")._
ProductSync = require("../lib/product-sync")
Config = require('../config').config
product = require("../models/product.json")
Rest = require("sphere-node-connect").Rest
OAuth2 = require("sphere-node-connect").OAuth2
Q = require("q")

# Increase timeout
jasmine.getEnv().defaultTimeoutInterval = 10000

xdescribe "Integration test", ->
  PRODUCT_ID = "79339393-6f12-4caf-b357-12b51b89bbcc"

  beforeEach ->
    @sync = new ProductSync config: Config.prod

  afterEach ->
    @sync = null

  it "should get products", (done)->
    @sync._rest.GET "/product-projections/#{PRODUCT_ID}?staged=true", (error, response, body)->
      expect(response.statusCode).toBe 200
      json = JSON.parse(body)
      expect(json).toBeDefined()
      expect(json.id).PRODUCT_ID
      done()

  it "should return 404 if product is not found", (done)->
    @sync._rest.GET "/product-projections/123", (error, response, body)->
      expect(response.statusCode).toBe 404
      done()

  it "should update a product", (done)->
    timestamp = new Date().getTime()
    NEW_PRODUCT =
      id: product.id
      name: product.name
      description: product.description
      slug:
        en: "integration-sync-#{timestamp}"
    callMe = (e, r, b)->
      expect(r.statusCode).toBe 200
      console.error b unless r.statusCode is 200
      updated = JSON.parse(b)
      expect(updated).toBeDefined()
      done()
    @sync._rest.GET "/product-projections/#{PRODUCT_ID}?staged=true", (error, response, body)=>
      expect(response.statusCode).toBe 200
      console.error body unless response.statusCode is 200
      old_product = JSON.parse(body)
      @sync.buildActions(NEW_PRODUCT, old_product).update(callMe)

  it "should update a product with different prices", (done)->
    timestamp = new Date().getTime()
    NEW_PRODUCT =
      id: product.id
      name: product.name
      description: product.description
      slug: product.slug
      masterVariant:
        id: 1
        prices: [
          {
            value:
              currencyCode: "EUR"
              centAmount: timestamp
          },
          {
            value:
              currencyCode: "EUR"
              centAmount: timestamp
            country: "DE"
          }
        ]
        attributes: []
      variants: [
        {
          id: 2
          prices: [
            {
              value:
                currencyCode: "EUR"
                centAmount: timestamp
            },
            {
              value:
                currencyCode: "EUR"
                centAmount: 10000
              customerGroup:
                typeId: "customer-group"
                id:"984a64de-24a4-42c0-868b-da7abfe1c5f6"
            },
            {
              value:
                currencyCode: "EUR"
                centAmount: timestamp
              customerGroup:
                typeId: "customer-group"
                id: "59c64f80-6472-474e-b5be-dc57b45b2faf"
            }
          ]
          attributes: []
        }
      ]
    callMe = (e, r, b)->
      expect(r.statusCode).toBe 200
      console.error b unless r.statusCode is 200
      updated = JSON.parse(b)
      expect(updated).toBeDefined()
      done()
    @sync._rest.GET "/product-projections/#{PRODUCT_ID}?staged=true", (error, response, body)=>
      expect(response.statusCode).toBe 200
      console.error body unless response.statusCode is 200
      old_product = JSON.parse(body)
      @sync.buildActions(NEW_PRODUCT, old_product).update(callMe)


describe "Integration test between projects", ->

  beforeEach (done)->
    getAuthToken = (config)->
      d = Q.defer()
      oa = new OAuth2 config: config
      oa.getAccessToken (error, response, body)->
        if body
          data = JSON.parse(body)
          optionsApi = _.clone(config)
          optionsApi.access_token = data.access_token
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
    ).fail (err)-> throw new Error(err)

  afterEach ->
    @restStaging = null
    @restProd = null
    @sync = null

  it "should sync products with same SKU", (done)->
    triggerFail = (e)=> @fail new Error e.join("\n")

    getProducts = (rest)->
      deferred = Q.defer()
      rest.GET "/product-projections?staged=true", (error, response, body)->
        if response.statusCode is 200
          results = JSON.parse(body).results
          deferred.resolve results
        else
          deferred.reject body
      deferred.promise

    searchProduct = (rest, value, prod)->
      deferred = Q.defer()
      predicate = "masterVariant(sku=\"#{value}\")"
      rest.GET "/product-projections?where=#{encodeURIComponent(predicate)}&staged=true", (error, response, body)->
        if response.statusCode is 200
          results = JSON.parse(body).results
          deferred.resolve
            product: prod
            results: results
        else
          deferred.reject body
      deferred.promise

    syncProducts = (sync, new_product, old_product)->
      deferred = Q.defer()
      try
        sync.buildActions(new_product, old_product).update (e, r, b)->
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
          updates.push syncProducts(@sync, resolver.product, stagingProd)
      Q.allSettled updates
    ).then((results)->
      errors = []
      _.each results, (result)->
        if result.state is "fulfilled"
          expect(result.value).toBe true
        else
          errors.push result.reason
      if errors.length > 0
        triggerFail errors
        done()
      else
        done()
    ).fail (err)-> triggerFail [err]
