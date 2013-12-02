#################
# Helper methods
#################

exports.getDeltaValue = (arr)->
  size = arr.length
  switch size
    when 1 #new
      arr[0]
    when 2 #update
      arr[1]
    when 3 #delete
      undefined
