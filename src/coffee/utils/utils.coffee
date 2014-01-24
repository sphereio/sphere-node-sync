_ = require("underscore")._
jsondiffpatch = require("jsondiffpatch")

###
Base Utils class
###
class Utils

  diff: (old_obj, new_obj)->
    # provide a hash function to work with objects in arrays
    jsondiffpatch.config.objectHash = (obj)-> obj.id or obj._id or obj.name
    jsondiffpatch.diff(old_obj, new_obj)

###
Exports object
###
module.exports = Utils