_ = require 'underscore'
Q = require 'q'
CategorySync = require '../../lib/sync/category-sync'
Config = require('../../config').config

# Increase timeout
jasmine.getEnv().defaultTimeoutInterval = 60000

describe 'Integration test :: Category', ->

  beforeEach (done) ->
    @sync = new CategorySync
      config: Config.staging
      logConfig:
        levelStream: 'error'
        levelFile: 'error'

    @sync._client.categories.perPage(0).fetch()
    .then (result) =>
      categories = result.body.results
      if categories.length is 0
        Q()
      else
        dels = _.map categories, (cat) =>
          @sync._client.categories.byId(cat.id).delete(cat.version)
        Q.all(dels)
    .then (result) ->
      done()
    .fail (error) ->
      done(_.prettify error)
    .done()

  it 'should update a category', (done) ->
    cat =
      name:
        en: 'myCategory'
      slug:
        en: 'nice-url'
    catChanged =
      name:
        en: 'CHANGED'
      slug:
        en: 'nice-url'

    @sync._client.categories.save cat
    .then (result) =>
      expect(result.statusCode).toBe 201
      @sync.buildActions(catChanged, result.body).update()
    .then (result) ->
      expect(result.statusCode).toBe 200
      expect(result.body.name.en).toBe 'CHANGED'
      done()
    .fail (error) ->
      done(_.prettify error)
    .done()