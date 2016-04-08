# Check if array contains item
Array.prototype.includes = (needle) ->
  len = this.length

  if len is 0
    return false

  NaNcheck = (x) -> x isnt x

  for item in this
    if (item is needle) or ( (NaNcheck item) and (NaNcheck needle) )
      return true

  return false


# Loop over a hash
Object.prototype.map = (callback) ->
  for own k, v of this
    callback k, v


# Remove item from array
Array.prototype.remove = (item) ->
  index = this.indexOf item

  if index >= 0
    this.splice index, 1
