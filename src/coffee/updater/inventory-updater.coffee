_ = require('underscore')._
Q = require('q')
CommonUpdater = require('./common-updater')
InventorySync = require('../sync/inventory-sync')

###
Inventory Updater class
###
class InventoryUpdater extends CommonUpdater

  CHANNEL_REF_NAME = 'supplyChannel'

  constructor: (opts = {}) ->
    super(opts)
    @sync = new InventorySync opts
    @rest = @sync._rest
    @existingInventoryEntries = {}
    @

  createInventoryEntry: (sku, quantity, expectedDelivery, channelId) ->
    entry =
      sku: sku
      quantityOnStock: parseInt(quantity)
    entry.expectedDelivery = expectedDelivery if expectedDelivery
    if channelId
      entry[CHANNEL_REF_NAME] =
        typeId: 'channel'
        id: channelId
    entry

  ensureChannelByKey: (rest, channelKey) ->
    deferred = Q.defer()
    query = encodeURIComponent("key=\"#{channelKey}\"")
    rest.GET "/channels?where=#{query}", (error, response, body) ->
      if error
        deferred.reject 'Error on getting channel: ' + error
        return
      if response.statusCode is 200
        channels = body.results
        if _.size(channels) is 1
          deferred.resolve channels[0]
          return
      # can't find it - let's create the channel
      channel =
        key: channelKey
      rest.POST '/channels', JSON.stringify(channel), (error, response, body) ->
        if error
          deferred.reject 'Error on creating channel: ' + error
        else if response.statusCode is 201
          deferred.resolve body
        else
          deferred.reject 'Problem on creating channel: ' + body
    deferred.promise

  allInventoryEntries: (rest) ->
    deferred = Q.defer()
    rest.GET '/inventory?limit=0', (error, response, body) ->
      if error
        deferred.reject 'Error on getting all inventory entries: ' + error
      else if response.statusCode isnt 200
        deferred.reject 'Problem on getting all inventory entries: ' + body
      else
        deferred.resolve body.results
    deferred.promise

  initMatcher: ->
    deferred = Q.defer()
    @allInventoryEntries(@rest).then (existingEntries) =>
      @existingInventoryEntries = existingEntries
      deferred.resolve existingEntries
    .fail (msg) ->
      deferred.reject msg
    deferred.promise

  match: (s) ->
    _.find @existingInventoryEntries, (entry) ->
      return false unless entry.sku is s.sku
      if _.has(entry, CHANNEL_REF_NAME)
        if _.has(s, CHANNEL_REF_NAME)
          return true if entry[CHANNEL_REF_NAME].id is s[CHANNEL_REF_NAME].id
      else
        return true unless _.has(s, CHANNEL_REF_NAME)
      false

  createOrUpdate: (inventoryEntries, callback) ->
    if _.size(inventoryEntries) is 0
      return @returnResult true, 'Nothing to do.', callback
    posts = []
    @initProgressBar 'Updating inventory', _.size(inventoryEntries)
    for entry in inventoryEntries
      existingEntry = @match(entry)
      if existingEntry
        posts.push @update(entry, existingEntry)
      else
        posts.push @create(entry)

    @processInBatches posts, callback

  processInBatches: (posts, callback, numberOfParallelRequest = 50, acc = []) =>
    current = _.take posts, numberOfParallelRequest
    Q.all(current).then (msg) =>
      messages = acc.concat(msg)
      if _.size(current) < numberOfParallelRequest
        @returnResult true, messages, callback
      else
        @processInBatches _.tail(posts, numberOfParallelRequest), callback, numberOfParallelRequest, messages
    .fail (msg) =>
      @returnResult false, msg, callback

  update: (entry, existingEntry) ->
    deferred = Q.defer()
    @sync.buildActions(entry, existingEntry).update (error, response, body) =>
      @tickProgress()
      if error
        deferred.reject 'Error on updating inventory entry: ' + error
      else
        if response.statusCode is 200
          deferred.resolve 'Inventory entry updated.'
        else if response.statusCode is 304
          deferred.resolve 'Inventory entry update not neccessary.'
        else
          deferred.reject 'Problem on updating existing inventory entry: ' + body
    deferred.promise

  create: (stock) ->
    deferred = Q.defer()
    @rest.POST '/inventory', JSON.stringify(stock), (error, response, body) =>
      @tickProgress()
      if error
        deferred.reject 'Error on creating new inventory entry: ' + error
      else
        if response.statusCode is 201
          deferred.resolve 'New inventory entry created.'
        else
          deferred.reject 'Problem on creating new inventory entry: ' + body
    deferred.promise

###
Exports object
###
module.exports = InventoryUpdater