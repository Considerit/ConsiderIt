require './responsive_vars'

####
# Make the DIV, SPAN, etc.
for el of React.DOM
  window[el.toUpperCase()] = React.DOM[el]

window.styles = ""

window.TRANSITION_SPEED = 700   # Speed of transition from results to crafting (and vice versa) 

window.LIVE_UPDATE_INTERVAL = 1000 * 60

# live updating
setInterval ->
  dependent_keys = []
  for key of arest.components_4_key.hash
    if key[0] == '/' && arest.components_4_key.get(key).length > 0 && \
       !key.match(/\/(user|opinion|proposal|point)\//)

      if key != '/current_user' || fetch('/current_user').logged_in
        arest.serverFetch(key)
        #console.log "FETCHING #{key}"

, LIVE_UPDATE_INTERVAL 

window.POINT_MOUTH_WIDTH = 17

##################
# Colors
#
# Colors are primarily stored in the database (to allow customers & Kev to self-brand).
# See @server/models/subdomain#branding_info for hardcoding color values
# when doing development. 

window.focus_blue = '#2478CC'
window.logo_red = "#B03A44"
window.default_avatar_in_histogram_color = '#d3d3d3'
window.considerit_gray = '#f6f7f9'

window.parseColor = (color_str) -> 
  test = document.createElement('div')
  test.style.color = color_str

  color = test.style.color
            .match(/^rgb\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)$/i)
  if color
    return {
      r: color[1]
      g: color[2]
      b: color[3]
    }
    
  else 

    console.error "Color #{color_str} could not be parsed"
    return {
      r: 0
      g: 0
      b: 0
    }    

window.addOpacity = (color, opacity) -> 
  c = parseColor color
  "rgba(#{c.r},#{c.g},#{c.b},#{opacity}"

# fixed saturation & brightness; random hue
# adapted from http://martin.ankerl.com/2009/12/09/how-to-create-random-colors-programmatically/
golden_ratio_conjugate = 0.618033988749895

window.getNiceRandomHues = (num, seed) -> 
  h = seed or .5

  hues = []
  i = num
  while i > 0
    hues.push h % 1
    h += golden_ratio_conjugate
    i -= 1
  hues

window.hsv_to_rgb = (h,s,v) -> 
  h_i = Math.floor(h*6)
  f = h*6 - h_i
  p = v * (1 - s)
  q = v * (1 - f*s)
  t = v * (1 - (1 - f) * s)
  [r, g, b] = [v, t, p] if h_i==0
  [r, g, b] = [q, v, p] if h_i==1
  [r, g, b] = [p, v, t] if h_i==2
  [r, g, b] = [p, q, v] if h_i==3
  [r, g, b] = [t, p, v] if h_i==4
  [r, g, b] = [v, p, q] if h_i==5

  "rgb(#{Math.round(r*256)}, #{Math.round(g*256)}, #{Math.round(b*256)})"


# backgroundColorAtCoord
#
# Makes best effort to determine the pixel color at a particular
# coordinate. "Best" because determining the pixel value of a 
# IMG or background image is a bit fraught. 
# 
# We can return a good answer immediately if there are no images at 
# the stacked elements at the coords, or all images that contributor 
# color at that coord are loaded. We must wait until all images are
# loaded however, which is why there is a callback for returning a 
# better answer asynchronously. This method will always return an 
# answer immediately, but if you know that there is an image in the 
# region of inquiry, make sure you supply a callback. 
#
# TODO: 
#     - We only see background-image if it is 
#       explicitly set. But you can specify an image via the 
#       background property. Handle that case. 
#     - Opacity is NOT handled
#     - Cross-domain images not supported 
#       http://stackoverflow.com/questions/22097747
#
# The answer is returned as { rgb: {r, g, b, a}, hsl: {h, s, l, a} }
# If an answer couldn't be immediately determined, null is returned
#
# callback (optional, but recommended): 
#   Called when we have the best answer to the question possible. Is 
#   passed a color object: { rgb: {r, g, b, a}, hsl: {h, s, l, a} }
#
# behind_el (optional): 
#   An element. If specified, we don't examine decendents of behind_el
#   when determining the background color at a coord. Example use:
#   if you are determining the background color at a particular place, 
#   but want to ignore an avatar image or something that might be 
#   sitting in the vicinity. 
#   

md5 = require './vendor/md5'
require './vendor/colorthief'

window.backgroundColorAtCoord = (x, y, callback, behind_el) -> 
  hidden_els = []

  el = document.elementFromPoint(x,y)

  while el && el.tagName not in ['BODY', 'HTML']

    is_image = el.tagName == 'IMG' || $(el).css('background-image') != 'none'

    # Skip this element if it doesn't contribute to background color
    # or if it is a decendent of behind_el
    rgb = parseCssRgb $(el).css('background-color')
    skip_element = (behind_el && $(behind_el).has($(el)).length > 0) ||
                    (!is_image && rgb.a == 0)

    if skip_element
      hidden_els.push [el, el.style.visibility]
      el.style.visibility = 'hidden'
      el = document.elementFromPoint(x,y)

    else if !is_image

      rgb = parseCssRgb $(el).css('background-color')

      hsl = rgb_to_hsl rgb
      color = {rgb, hsl} 
      callback color if callback
      break

    else 
      if el.tagName != 'IMG'
        # we have to extract a background url into a temporary IMG
        # element so that it can be processed by colorThief

        url = $(el).css('background-image')
                .replace(/^url\(["']?/, '').replace(/["']?\)$/, '')
      else 
        url = el.src

      # make sure we only use local images because Cross-domain images 
      # are not supported -- see http://stackoverflow.com/questions/22097747
      a = document.createElement("a")
      a.href = url || el.src
      url = a.pathname

      img =$("<IMG src='#{url}' />")

      imagePoll = -> 
        if img[0].complete
          colorThief = new ColorThief()
          rgb = colorThief.getColor img[0], 5, true
          rgb = 
            r: rgb[0]
            g: rgb[1]
            b: rgb[2]
          hsl = rgb_to_hsl rgb
          color = {rgb, hsl} 
          callback color if callback
          return color
        else 
          setTimeout imagePoll, 50
          return null

      color = imagePoll()
      break

  # restore visibility for all elements we've looked at
  for el in hidden_els
    el[0].style.visibility = el[1]

  return color

window.rgb_to_hsl = (rgb) ->
  r = rgb.r / 255
  g = rgb.g / 255
  b = rgb.b / 255

  max = Math.max(r, g, b)
  min = Math.min(r, g, b)
  l = (max + min) / 2
  if max is min
    h = s = 0 # achromatic
  else
    d = max - min
    s = (if l > 0.5 then d / (2 - max - min) else d / (max + min))
    switch max
      when r
        h = (g - b) / d + ((if g < b then 6 else 0))
      when g
        h = (b - r) / d + 2
      when b
        h = (r - g) / d + 4
    h /= 6
  h: h
  s: s
  l: l

parseCssRgb = (rgb_str) ->
  if rgb_str == 'transparent'
    {r: 0, g: 0, b: 0, a: 0}
  else  
    rgb = /^rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*(1|0(\.\d+)?))?\)$/.exec(rgb_str)

    r: parseInt rgb[1]
    g: parseInt rgb[2]
    b: parseInt rgb[3]
    a: if rgb.length > 4 && rgb[4]? then parseInt(rgb[4]) else 1

window.isLightBackground = (el, callback) -> 
  coords = getCoords el

  color = backgroundColorAtCoord coords.cx, coords.cy, (color) -> 
    callback color.hsl.l > .75
  , el

  color?.hsl.l > .75

#########################

#### Layout

window.getCoords = (el) ->
  rect = el.getBoundingClientRect()
  docEl = document.documentElement

  offset = 
    top: rect.top + window.pageYOffset - docEl.clientTop
    left: rect.left + window.pageXOffset - docEl.clientLeft
  _.extend offset,
    cx: offset.left + rect.width / 2
    cy: offset.top + rect.height / 2


#### browser

# stored in public/images
window.asset = (name) -> 
  app = fetch('/application')

  if app.app?
    "#{app.asset_host or ''}/images/#{name}"
  else 
    # app isn't loaded yet...
    ""


##
# logging

window.on_ajax_error = () ->
  (root = fetch('root')).server_error = true
  save(root)
window.on_client_error = (e) ->
  if navigator.userAgent.indexOf('PhantomJS') >= 0
    # don't care about errors on phtanomjs web crawlers
    return

  save(
    key: '/new/client_error'
    stack: e.stack
    message: e.message or e.description
    name: e.name
    line_number: e.lineNumber
    column_number: e.columnNumber
    )

window.writeToLog = (entry) ->
  _.extend entry, 
    key: '/new/log'
    where: fetch('location').url

  save entry



##
# Helpers

# Takes an ISO time and returns a string representing how
# long ago the date represents.
# from: http://stackoverflow.com/questions/7641791
window.prettyDate = (time) ->
  date = new Date(time) #new Date((time || "").replace(/-/g, "/").replace(/[TZ]/g, " "))
  diff = (((new Date()).getTime() - date.getTime()) / 1000)
  day_diff = Math.floor(diff / 86400)

  return if isNaN(day_diff) || day_diff < 0 || day_diff >= 31

  # TODO: pluralize properly (e.g. 1 days ago, 1 weeks ago...)
  day_diff == 0 && (
    diff < 60 && "just now" || 
    diff < 120 && "1 minute ago" || 
    diff < 3600 && Math.floor(diff / 60) + " minutes ago" || 
                              diff < 7200 && "1 hour ago" || 
                              diff < 86400 && Math.floor(diff / 3600) + " hours ago") || 
                              day_diff == 1 && "Yesterday" || 
                              day_diff < 7 && day_diff + " days ago" || 
                              day_diff < 31 && Math.ceil(day_diff / 7) + " weeks ago"

window.shorten = (str, max_length) ->
  max_length ||= 70
  "#{str.substring(0, max_length)}#{if str.length > max_length then '...' else ''}"

window.inRange = (val, min, max) ->
  return val <= max && val >= min

window.capitalize = (string) -> string.charAt(0).toUpperCase() + string.substring(1)

window.L = window.LOADING_INDICATOR = DIV null, 'Loading...'


window.reset_key = (obj_or_key, updates) -> 
  updates = updates or {}
  if !obj_or_key.key
    obj_or_key = fetch obj_or_key

  for own k,v of obj_or_key
    if k != 'key'
      delete obj_or_key[k]

  _.extend obj_or_key, updates
  save obj_or_key


window.splitParagraphs = (user_content) ->
  if !user_content
    return SPAN null
    
  user_content = user_content.replace(/(<li>|<br\s?\/?>|<p>)/g, '\n') #add newlines
  user_content = user_content.replace(/(<([^>]+)>)/ig, "") #strips all tags

  # autolink. We'll insert a delimiter ('(*-&)') to use for splitting later.
  # regex adapted from https://github.com/bryanwoods/autolink-js, MIT license, author Bryan Woods
  hyperlink_pattern = ///
    (^|[\s\n]) # Capture the beginning of string or line or leading whitespace
    (
      (?:https?):// # Look for a valid URL protocol (non-captured)
      [\-A-Z0-9+\u0026\u2019@#/%?=()~_|!:,.;]* # Valid URL characters (any number of times)
      [\-A-Z0-9+\u0026@#/%=~()_|] # String must end in a valid URL character
    )
  ///gi
  user_content = user_content.replace(hyperlink_pattern, "$1(*-&)link:$2(*-&)")
  paragraphs = user_content.split(/(?:\r?\n)/g)

  for para,idx in paragraphs
    P key: "para-#{idx}", 
      # now split around all links
      for text,idx in para.split '(*-&)'
        if text.substring(0,5) == 'link:'
          A key: idx, href: text.substring(5, text.length), target: '_blank',
            text.substring(5, text.length)
        else  
          SPAN key: idx, text

# Computes the width of some text given some styles empirically
width_cache = {}
window.widthWhenRendered = (str, style) -> 
  # This DOM manipulation is relatively expensive, so cache results
  key = JSON.stringify _.extend({str: str}, style)
  if key not of width_cache
    $el = $("<span id='width_test'>#{str}</span>").css(style)
    $('#content').append($el)
    width = $('#width_test').width()
    $('#width_test').remove()
    width_cache[key] = width
  width_cache[key]


height_cache = {}
window.heightWhenRendered = (str, style) -> 
  # This DOM manipulation is relatively expensive, so cache results
  key = JSON.stringify _.extend({str: str}, style)
  if key not of height_cache
    $el = $("<div id='height_test'>#{str}</div>").css(style)
    $('#content').append($el)
    height = $('#height_test').height()
    $('#height_test').remove()
    height_cache[key] = height

  height_cache[key]


# maps an opinion stance in [-1, 1] to a pixel value [0, width]
window.translateStanceToPixelX = (stance, width) -> (stance + 1) / 2 * width

# Maps a pixel value [0, width] to an opinion stance in [-1, 1] 
window.translatePixelXToStance = (pixel_x, width) -> 2 * (pixel_x / width) - 1




##############################
## Styles
############

## CSS functions

# Mixin for mediaquery for retina screens. 
# Adapted from https://gist.github.com/ddemaree/5470343
window.css = {}

css_as_str = (attrs) -> _.keys(attrs).map( (p) -> "#{p}: #{attrs[p]}").join(';') + ';'

css.crossbrowserify = (props, as_str = false) -> 

  prefixes = ['-webkit-', '-ms-', '-mox-', '-o-']
  if props.transform
    for prefix in prefixes
      props["#{prefix}transform"] = props.transform

  if props.transition
    for prefix in prefixes
      props["#{prefix}transition"] = props.transition.replace("transform", "#{prefix}transform")

  if props.userSelect
    _.extend props,
      MozUserSelect: props.userSelect
      WebkitUserSelect: props.userSelect
      msUserSelect: props.userSelect

  if as_str then css_as_str(props) else props

css.grayscale = (props) ->
  if browser.is_mobile
    console.log "CAUTION: grayscale filter on mobile can cause crashes"
    
  _.extend props,
    WebkitFilter: 'grayscale(100%)'
    filter: 'grayscale(100%)'  
  props

css.grab_cursor = (selector)->
  """
  #{selector} {
    cursor: move;
    cursor: ew-resize;
    cursor: -webkit-grab;
    cursor: -moz-grab;
  } #{selector}:active {
    cursor: move;
    cursor: ew-resize;
    cursor: -webkit-grabbing;
    cursor: -moz-grabbing;
  }
  """

# Returns the style for a css triangle
# 
window.cssTriangle = (direction, color, width, height, style) -> 
  style = style or {}

  switch direction
    when 'top'
      border_width = "0 #{width/2}px #{height}px #{width/2}px"
      border_color = "transparent transparent #{color} transparent"
    when 'bottom'
      border_width = "#{height}px #{width/2}px 0 #{width/2}px"
      border_color = "#{color} transparent transparent transparent"
    when 'left'
      border_width = "#{height/2}px #{width}px #{height/2}px 0"
      border_color = "transparent #{color} transparent transparent"
    when 'right'
      border_width = "#{height/2}px 0 #{height/2}px #{width}px"
      border_color = "transparent transparent transparent #{color}"

  _.defaults style, 
    width: 0
    height: 0
    borderStyle: 'solid'
    borderWidth: border_width
    borderColor: border_color

  style



## CSS reset

window.styles += """
/* RESET
 * Eric Meyer's Reset CSS v2.0 (http://meyerweb.com/eric/tools/css/reset/)
 * http://cssreset.com
 */
html, body, div, span, applet, object, iframe,
h1, h2, h3, h4, h5, h6, p, blockquote, pre,
a, abbr, acronym, address, big, cite, code,
del, dfn, em, img, ins, kbd, q, s, samp,
small, strike, strong, sub, sup, tt, var,
b, u, i, center,
dl, dt, dd, ol, ul, li,
fieldset, form, label, legend,
table, caption, tbody, tfoot, thead, tr, th, td,
article, aside, canvas, details, embed,
figure, figcaption, footer, header, hgroup,
menu, nav, output, ruby, section, summary,
time, mark, audio, video {
  margin: 0;
  padding: 0;
  border: 0;
  font-size: 100%;
  font: inherit;
  vertical-align: baseline;
  line-height: 1.4; }

hr {
  display: block;
  height: 1px;
  border: 0;
  border-top: 1px solid #cccccc;
  margin: 0;
  padding: 0; }

body {
  min-height: 100%; }

ol, ul {
  list-style: none;
  list-style-position: inside; }

blockquote, q {
  quotes: none; }

blockquote:before, blockquote:after,
q:before, q:after {
  content: '';
  content: none; }

table {
  border-collapse: collapse;
  border-spacing: 0; }

td, th {vertical-align: top;}

h1, h2, h3, h4, h5, h6, strong {
  font-weight: bold; }

em, i {
  font-style: italic; }

b, strong { font-weight: bold; }

/* ELEMENT DEFAULTS */
* {
  -webkit-box-sizing: border-box;
  -moz-box-sizing: border-box;
  box-sizing: border-box; }

a {
  color: inherit;
  outline: none;
  cursor: pointer;
  text-decoration: none; }
  a img {
    border: none; }

table {
  border-collapse: separate; }

ul {
  margin: 0;
  list-style-type: disc; }

ol {
  margin: 0;
  list-style-type: decimal; }

blockquote {
  quotes: '"' '"' "'" "'"; }
  blockquote:before {
    content: open-quote;}
  blockquote:after {
    content: close-quote;}

"""

# some basic styles
window.styles += """

body, h1, h2, h3, h4, h5, h6 {
  color: black; }

body, input, button, textarea {
  font-family: 'Avenir Next W01', 'Avenir Next', 'Lucida Grande', 'Lucida Sans Unicode', 'Helvetica Neue', Helvetica, Verdana, sans-serif; }

.content {
  position: relative;
  font-size: 16px;
  color: black;
  min-height: 500px; }

.button {
  font-size: 16px; }

.button, button, input[type='submit'] {
  outline: none;
  cursor: pointer;
  text-align: center; }


.flipped {
  -moz-transform: scaleX(-1);
  -o-transform: scaleX(-1);
  -webkit-transform: scaleX(-1);
  transform: scaleX(-1);
  filter: FlipH;
  -ms-filter: 'FlipH'; }

.primary_button, .primary_cancel_button {
  border-radius: 16px;
  text-align: center;
  padding: 3px;
  cursor: pointer; }

.primary_button {
  background-color: #{focus_blue};
  color: white;
  font-size: 29px;
  margin-top: 14px;
  box-shadow: 0px 1px 0px black;
  border: none;
  padding: 8px 36px; }

.primary_button.disabled {
  background-color: #eeeeee;
  color: #cccccc;
  box-shadow: none;
  border: none;
  cursor: wait; }

a.primary_cancel_button {
  color: #888888;
  margin-top: 0.5em; }

a.cancel_opinion_button {
  float: right;
  margin-top: 0.5em; }

button.primary_button, input[type='submit'] {
  display: inline-block; }

"""
