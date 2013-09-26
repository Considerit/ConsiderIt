do (_) ->
  _.templateSettings =  
    interpolate : /\{\{(.+?)\}\}/g
    evaluate : /\(\((.+?)\)\)/g

  _.mixin
    compactObject : (o) ->
      _.each o, (v, k) ->
        delete o[k] if !v
      o
