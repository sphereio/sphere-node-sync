_ = require 'underscore'
jsondiffpatch = require 'jsondiffpatch'

###
Base Utils class
###
class Utils

  constructor: (options = {}) ->
    diffConfig = _.defaults options,
      # provide a hash function to work with objects in arrays
      objectHash: (obj) ->
        obj.id or obj._id or obj.name
      arrays:
        # default true, detect items moved inside the array (otherwise they will be registered as remove+add)
        detectMove: true
        # default false, the value of items moved is not included in deltas
        includeValueOnMove: true

    @diffPatch = jsondiffpatch.create diffConfig

  diff: (old_obj, new_obj) -> @diffPatch.diff(old_obj, new_obj)

###
Exports object
###
module.exports = Utils
