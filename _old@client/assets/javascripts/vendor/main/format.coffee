# from https://github.com/bryanwoods/autolink-js/blob/master/autolink.coffee
autoLink = (str) ->
  url_pattern =
    /(^|\s)(\b(https?|ftp):\/\/[\-A-Z0-9+\u0026@#\/%?=~_|!:,.;]*[\-A-Z0-9+\u0026@#\/%=~_|])/gi

  return str.replace url_pattern, "$1<a href='$2' target=\"_blank\">$2</a>"


# from https://makandracards.com/makandra/1395-simple_format-helper-for-javascript & https://gist.github.com/huned/865391

newlines_regex = /\n{2,}/g
carriage_rtn_regex = /\r\n/g
br_regex = /<br>/g
redundant_break_regex = /<\/p>\n/g

simpleFormat = (str) ->
  # str = $.trim str.replace(/\r\n?/, "").replace(/\n?/, "")
  # if str.length > 0
  #   str = "<p>#{str.replace(/\n\n+/g, '</p><p>').replace(/\n/g, '<br />')}</p>"

  # str
  str = $.trim(str)
  str = str.replace carriage_rtn_regex, '\n'
  str = str.replace br_regex, '\n'
  str = str.replace redundant_break_regex, '<p/>'
  str = str.replace newlines_regex, '<br /><br />'
  str



window.htmlFormat = (str) -> 
  return '' if !str
  simpleFormat( autoLink( str ) )