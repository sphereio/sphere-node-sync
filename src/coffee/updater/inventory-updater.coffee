Q = require 'q'
_ = require 'underscore'
_.mixin require('sphere-node-utils')._u
{Qbatch} = require 'sphere-node-utils'
CommonUpdater = require './common-updater'
InventorySync = require '../sync/inventory-sync'

###
(abstract) Inventory Updater class
  This class includes some common functions to handle inventory updates.
###
class InventoryUpdater extends CommonUpdater

  CHANNEL_REF_NAME = 'supplyChannel'

  constructor: (opts = {}) ->
    super(opts)
    @sync = new InventorySync opts
    @rest = @sync._rest
    @existingInventoryEntries = {}

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

  ensureChannelByKey: (rest, channelKey, channelRolesForCreation = ['InventorySupply']) ->
    deferred = Q.defer()
    query = encodeURIComponent("key=\"#{channelKey}\"")
    rest.GET "/channels?where=#{query}", (error, response, body) ->
      foundChannel = false
      if error
        deferred.reject 'Error on getting channel: ' + error
      else if response.statusCode is 200
        channels = body.results
        if _.size(channels) is 1
          deferred.resolve channels[0]
          foundChannel = true
      unless foundChannel
        # can't find it - let's create the channel
        channel =
          key: channelKey
          roles: channelRolesForCreation
        rest.POST '/channels', channel, (error, response, body) ->
          if error
            deferred.reject 'Error on creating channel: ' + error
          else if response.statusCode is 201
            deferred.resolve body
          else
            deferred.reject 'Error on creating channel: ' + body
    deferred.promise

  allInventoryEntries: (rest, queryString) ->
    deferred = Q.defer()
    rest.PAGED '/inventory?#{queryString}', (error, response, body) ->
      if error
        deferred.reject "Error on fetching all inventory entries: #{error}"
      else
        if response.statusCode is 200
          deferred.resolve body.results
        else
          deferred.reject "Error on fetching all inventory entries: #{body}"
    , (progress) -> deferred.notify progress
    deferred.promise

  initMatcher: (queryString) ->
    deferred = Q.defer()
    @allInventoryEntries(@rest, queryString).then (existingEntries) =>
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

    Qbatch.all(posts)
    .then (results) => @returnResult true, results, callback
    .fail (error) => @returnResult false, error, callback

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
          deferred.reject 'Error on updating existing inventory entry: ' + body
    deferred.promise

  create: (stock) ->
    deferred = Q.defer()
    @rest.POST '/inventory', stock, (error, response, body) =>
      @tickProgress()
      if error
        deferred.reject 'Error on creating new inventory entry: ' + error
      else
        if response.statusCode is 201
          deferred.resolve 'New inventory entry created.'
        else
          deferred.reject 'Error on creating new inventory entry: ' + body
    deferred.promise

###
Exports object
###
module.exports = InventoryUpdater
