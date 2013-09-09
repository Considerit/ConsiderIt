# from https://github.com/bryanwoods/autolink-js/blob/master/autolink.coffee
autoLink = (str) ->
  link_attributes = 'target="_blank"'
  url_pattern =
    /(^|\s)(\b(https?|ftp):\/\/[\-A-Z0-9+\u0026@#\/%?=~_|!:,.;]*[\-A-Z0-9+\u0026@#\/%=~_|])/gi

  return str.replace url_pattern, "$1<a href='$2'>$2</a>"


# from https://makandracards.com/makandra/1395-simple_format-helper-for-javascript & https://gist.github.com/huned/865391
simpleFormat = (str) ->
  # str = $.trim str.replace(/\r\n?/, "").replace(/\n?/, "")
  # if str.length > 0
  #   str = "<p>#{str.replace(/\n\n+/g, '</p><p>').replace(/\n/g, '<br />')}</p>"

  # str

  str = str.replace(/\r\n?/, "\n")
  str = $.trim(str)
  if str.length > 0
    str = "<p>#{str.replace(/\n/g, '<br />')}</p>"

  str



window.htmlFormat = (str) -> 
  return '' if !str
  simpleFormat( autoLink( str ) )