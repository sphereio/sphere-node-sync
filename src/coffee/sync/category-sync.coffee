{_} = require 'underscore'
{Rest} = require 'sphere-node-connect'
Sync = require '../sync/sync'
CategoryUtil = require '../utils/category-utils'

###
CategorySync Sync class
###
class CategorySync extends Sync
  constructor: (opts = {}) ->
    super(opts)
    # Override base utils
    @_utils = new CategoryUtil()
    @

  _doMapActions: (diff, new_obj, old_obj) ->
    actions = @_utils.actionsMap diff

  _doUpdate: (callback) ->
    @_rest.POST "/categories/#{@_data.updateId}", @_data.update, callback


###
Exports object
###
module.exports = CategorySync
