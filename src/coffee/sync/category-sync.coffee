_ = require 'underscore'
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
    actions = @_utils.actionsMap diff, new_obj

  _doUpdate: ->
    @_client.categories.byId(@_data.updateId).update(@_data.update)


###
Exports object
###
module.exports = CategorySync
