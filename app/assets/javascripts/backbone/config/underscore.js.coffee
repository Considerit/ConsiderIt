do (_) ->
  _.templateSettings =  
    interpolate : /\{\{(.+?)\}\}/g
    evaluate : /\(\((.+?)\)\)/g

  _.mixin
    compactObjectInPlace : (o) ->
      _.each o, (v, k) ->
        delete o[k] if !v
      o

    compactObject : (o) ->
      n = {}
      _.each o, (v,k) ->
        n[k] = v if v
      n

    delayIfWait : (wait, func) ->
      if wait > 0
        _.delay func, wait
      else
        func()
