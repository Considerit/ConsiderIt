do (_) ->
  _.templateSettings =  
    interpolate : /\{\{(.+?)\}\}/g
    evaluate : /\(\((.+?)\)\)/g