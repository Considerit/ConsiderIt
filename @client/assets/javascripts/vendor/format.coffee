# from https://github.com/bryanwoods/autolink-js/blob/master/autolink.coffee
autoLink = (str) ->
  url_pattern =
    /(^|\s)(\b(https?|ftp):\/\/[\-A-Z0-9+\u0026@#\/%?=~_|!:,.;]*[\-A-Z0-9+\u0026@#\/%=~_|])/gi

  return str.replace url_pattern, "$1<a href='$2' target=\"_blank\">$2</a>"
