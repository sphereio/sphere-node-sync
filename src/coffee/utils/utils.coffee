_ = require 'underscore'
jsondiffpatch = require 'jsondiffpatch'

###
Base Utils class
###
class Utils

  diff: (old_obj, new_obj) ->
    # provide a hash function to work with objects in arrays
    jsondiffpatch.config.objectHash = (obj) -> obj._MATCH_CRITERIA or obj.id or obj.name
    jsondiffpatch.diff(old_obj, new_obj)

###
Exports object
###
module.exports = Utils
