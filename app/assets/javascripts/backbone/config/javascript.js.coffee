# Array::insertAt = (index, item) ->
#   @splice(index, 0, item)
#   @


# from https://github.com/jashkenas/coffee-script/issues/452
window.mixOf = (base, mixins...) ->
  class Mixed extends base
  for mixin in mixins by -1
    for name, method of mixin::
      Mixed::[name] = method
  Mixed

