window.styles = ""

require './responsive_vars'
require './color'


#############
# ajax_submit_files_in_form: uploads a file using ajax, using HTML5 file API
# opts is hash with: 
#    form: css selector for the form element
#    type: the action type (default = POST)
#    additional_data: hash of more data to include when uploading
#    uri: the location to upload to (defaults to form's action attribute) 
#    success: callback when upload successful (optional)
#    error: callback when upload fails (optional)
window.ajax_submit_files_in_form = (opts) -> 
  opts ?= {}

  cb = (evt) ->
    if xhr.readyState == XMLHttpRequest.DONE
      status = xhr.status
      if status == 0 || (status >= 200 && status < 400)
        opts.success? xhr.responseText
      else
        opts.error? {response: xhr.responseText, status: status}

  form = document.querySelector(opts.form)
  frm = new FormData form
  for k,v of (opts.additional_data or {})
    frm.append k, v

  xhr = new XMLHttpRequest
  xhr.addEventListener 'readystatechange', cb, false
  xhr.open (opts.type or 'POST'), opts.uri or form.getAttribute('action'), true
  xhr.send frm



window.screencasting = ->
  window.__screencasting ?= fetch('location').query_params.screencasting == 'true'
  window.__screencasting

window.embedded_demo = ->
  window.__embedded_demo ?= fetch('location').query_params.embedded_demo == 'true'
  window.__embedded_demo
    
window.pad = (num, len) -> 
  str = num
  dec = str.split('.')
  i = 0 
  while i < len - dec[0].toString().length
    dec[0] = "0" + dec[0]
    i += 1

  dec[0] + if dec.length > 0 then '.' + dec[1] else ''


window.back_to_homepage_button = (style, text) -> 
  loc = fetch('location')
  homepage = loc.url == '/'

  hash = loc.url.split('/')[1].replace('-', '_')

  NAV 
    role: 'navigation'
    A
      className: 'back_to_homepage'
      title: 'back to homepage'
      key: 'back_to_homepage_button'
      "data-no-scroll": true
      href: "/##{hash}"
      style: _.defaults {}, style,
        fontSize: 43
        visibility: if homepage || !customization('has_homepage') then 'hidden' else 'visible'
        color: 'black'
        display: 'flex'
        alignItems: 'center'


      ChevronLeft(20)

      if text 
        SPAN 
          style: 
            paddingLeft: 20
          text 






####
# Make the DIV, SPAN, etc.
for el of ReactDOMFactories
  window[el.toUpperCase()] = React.createFactory(el) # ReactDOMFactories[el]

USE_STRICT_MODE = false
if USE_STRICT_MODE
  window['STRICTMODE'] = React.createFactory(React.StrictMode)

if ReactFlipToolkit?
  window.FLIPPER = React.createFactory(ReactFlipToolkit.Flipper)
  window.FLIPPED = React.createFactory(ReactFlipToolkit.Flipped)
  window.EXITCONTAINER = React.createFactory(ReactFlipToolkit.ExitContainer)


window.TRANSITION_SPEED = 700   # Speed of transition from results to crafting (and vice versa) 

window.LIVE_UPDATE_INTERVAL = 3 * 60 * 1000

# live updating
setInterval ->
  dependent_keys = []
  proposals = false 
  for key of arest.components_4_key.hash
    if key[0] == '/' && arest.components_4_key.get(key).length > 0 && \
       !key.match(/\/(current_user|user|opinion|point|subdomain|application|translations)/)

      if key.match(/\/proposal\/|\/proposals\//)
        proposals = true 
      else
        arest.serverFetch(key)

  if proposals 
    arest.serverFetch('/proposals')

, LIVE_UPDATE_INTERVAL 


# To help reduce the chance of clobbering forum customizations when multiple admins have windows open,
# we live update the subdomains object periodically for admins after they've been idle for a little while.
# This doesn't work if both admins are concurrently editing the configuration. 
do ->
  idle_time_before_subdomain_fetch = 30 * 60 * 1000

  reload_subdomain = ->
    # console.log "Idle for #{idle_time_before_subdomain_fetch / 1000}s, fetching subdomain"
    arest.serverFetch '/subdomain'

  time = 0
  resetTimer = ->
    # console.log('resetting timer')
    if time
      clearTimeout(time)
    time = setTimeout(reload_subdomain, idle_time_before_subdomain_fetch)

  window.addEventListener('load', resetTimer, true)
  for event in ['mousedown', 'mousemove', 'keydown', 'touchstart']
    document.addEventListener(event, resetTimer, true)



window.POINT_MOUTH_WIDTH = 17


# HEARTBEAT
# Any component that renders a HEARTBEAT will get rerendered on an interval.
# props: 
#   public_key: the key to store the heartbeat at
#   interval: length between pulses, in ms (default=1000)
# window.HEARTBEAT = ReactiveComponent
#   displayName: 'heartbeat'

#   render: ->   
#     beat = fetch(@props.public_key or 'pulse')
#     if !beat.beat?
#       setInterval ->   
#         beat.beat = (beat.beat or 0) + 1
#         save(beat)
#       , (@props.interval or 1000)

#     SPAN null




#### Layout

window.getCoords = (el) ->
  rect = el.getBoundingClientRect()
  docEl = document.documentElement

  offset = 
    top: rect.top + window.pageYOffset - docEl.clientTop
    left: rect.left + window.pageXOffset - docEl.clientLeft

  _.extend offset,
    width: rect.width
    height: rect.height
    cx: offset.left + rect.width / 2
    cy: offset.top + rect.height / 2
    right: offset.left + rect.width
    bottom: offset.top + rect.height


#### browser

# stored in public/images
window.asset = (name) -> 
  app = fetch('/application')

  if app.asset_host?
    a = "#{app.asset_host or ''}/images/#{name}"
  else 
    a = "#{window.asset_host or ''}/images/#{name}"

  a

#####
# data 
window.opinionsForProposal = (proposal) ->       
  opinions = fetch(proposal).opinions || []
  opinions





######
# Expands a key like 'slider' to one that is namespaced to a parent object, 
# like the current proposal. Will return a local key like 'proposal/345/slider' 
window.namespaced_key = (base_key, base_object) ->
  namespace_key = fetch(base_object).key 

  # don't store this on the server
  if namespace_key[0] == '/'
    namespace_key = namespace_key.substring(1, namespace_key.length)
  
  "#{namespace_key}_#{base_key}"

  

##
# logging

window.on_ajax_error = () ->
  root = fetch('root')
  root.server_error = true
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


logs_to_write = []
log_writer = null 

window.writeToLog = (entry) ->
  return 
  entry.where = fetch('location').url
  logs_to_write.push entry 
  if !log_writer 
    setTimeout -> 
      log_writer = setInterval -> 
        for log in logs_to_write
          log.key = '/new/log'
          save log 
        logs_to_write = []
      , 100
    , 2000



##
# Helpers

# Takes an ISO time and returns a string representing how
# long ago the date represents.
# from: http://stackoverflow.com/questions/7641791
window.prettyDate = (time) ->
  subdomain = fetch('/subdomain')

  date = new Date(time) #new Date((time || "").replace(/-/g, "/").replace(/[TZ]/g, " "))
  
  diff = (((new Date()).getTime() - date.getTime()) / 1000)
  day_diff = Math.floor(diff / 86400)

  return if isNaN(day_diff) || day_diff < 0

  if subdomain.lang != 'en'
    return "#{date.getMonth() + 1}/#{date.getDate() + 1}/#{date.getFullYear()}" 

  r = day_diff == 0 && (
    diff < 60 && "just now" || 
    diff < 120 && "1 minute ago" || 
    diff < 3600 && Math.floor(diff / 60) + " minutes ago" || 
                              diff < 7200 && "1 hour ago" || 
                              diff < 86400 && Math.floor(diff / 3600) + " hours ago") || 
                              day_diff == 1 && "Yesterday" || 
                              day_diff < 7 && day_diff + " days ago" || 
                              day_diff < 31 && Math.ceil(day_diff / 7) + " weeks ago" ||
                              "#{date.getMonth() + 1}/#{date.getDate() + 1}/#{date.getFullYear()}"

  r = r.replace('1 days ago', '1 day ago').replace('1 weeks ago', '1 week ago').replace('1 years ago', '1 year ago')
  r


window.inRange = (val, min, max) ->
  return val <= max && val >= min

window.capitalize = (string) -> string.charAt(0).toUpperCase() + string.substring(1)
window.capitalize_each_word = (str) -> str.replace /\b\w/g, (l) -> l.toUpperCase()

window.loading_indicator = DIV
                            className: 'loading sk-wave'
                            dangerouslySetInnerHTML: __html: """
                              <div class="sk-rect sk-rect1"></div>
                              <div class="sk-rect sk-rect2"></div>
                              <div class="sk-rect sk-rect3"></div>
                              <div class="sk-rect sk-rect4"></div>
                              <div class="sk-rect sk-rect5"></div>
                            """



window.LOADING_INDICATOR = window.loading_indicator


# loading indicator styles below are 
# Copyright (c) 2015 Tobias Ahlin, The MIT License (MIT)
# https://github.com/tobiasahlin/SpinKit
styles += """
.sk-wave {
  margin: 40px auto;
  width: 50px;
  height: 40px;
  text-align: center;
  font-size: 10px; }
  .sk-wave .sk-rect {
    background-color: rgba(223, 98, 100, .5);
    height: 100%;
    width: 6px;
    display: inline-block;
    -webkit-animation: sk-waveStretchDelay 1.2s infinite ease-in-out;
            animation: sk-waveStretchDelay 1.2s infinite ease-in-out; }
  .sk-wave .sk-rect1 {
    -webkit-animation-delay: -1.2s;
            animation-delay: -1.2s; }
  .sk-wave .sk-rect2 {
    -webkit-animation-delay: -1.1s;
            animation-delay: -1.1s; }
  .sk-wave .sk-rect3 {
    -webkit-animation-delay: -1s;
            animation-delay: -1s; }
  .sk-wave .sk-rect4 {
    -webkit-animation-delay: -0.9s;
            animation-delay: -0.9s; }
  .sk-wave .sk-rect5 {
    -webkit-animation-delay: -0.8s;
            animation-delay: -0.8s; }

@-webkit-keyframes sk-waveStretchDelay {
  0%, 40%, 100% {
    -webkit-transform: scaleY(0.4);
            transform: scaleY(0.4); }
  20% {
    -webkit-transform: scaleY(1);
            transform: scaleY(1); } }

@keyframes sk-waveStretchDelay {
  0%, 40%, 100% {
    -webkit-transform: scaleY(0.4);
            transform: scaleY(0.4); }
  20% {
    -webkit-transform: scaleY(1);
            transform: scaleY(1); } }
"""



window.shared_local_key = (key_or_object) -> 
  key = key_or_object.key || key_or_object
  if key[0] == '/'
    key = key.substring(1, key.length)
    "#{key}/shared"
  else 
    key


window.reset_key = (obj_or_key, updates) -> 
  updates = updates or {}
  if !obj_or_key.key
    obj_or_key = fetch obj_or_key

  for own k,v of obj_or_key
    if k != 'key'
      delete obj_or_key[k]

  _.extend obj_or_key, updates
  save obj_or_key


safe_string = (user_content) -> 
  user_content = user_content.replace(/(<li>|<br\s?\/?>|<p>)/g, '\n') #add newlines
  user_content = user_content.replace(/(<([^>]+)>)/ig, "") #strips all tags

  # autolink. We'll insert a delimiter ('(*-&)') to use for splitting later.
  # regex adapted from https://github.com/bryanwoods/autolink-js, MIT license, author Bryan Woods
  hyperlink_pattern = ///
    (^|[\s\n]) # Capture the beginning of string or line or leading whitespace
    (
      (?:https?):// # Look for a valid URL protocol (non-captured)
      [\-A-Z0-9+\u0026\u2019@#/%?=()\[\]\-\$&\*~_|!:,.;']* # Valid URL characters (any number of times)
      [\-A-Z0-9+\u0026@#/%=~()_|] # String must end in a valid URL character
    )
  ///gi
  user_content = user_content.replace(hyperlink_pattern, "$1(*-&)link:$2(*-&)")

  user_content 

window.splitParagraphs = (user_content, append) ->
  if !user_content
    return SPAN null
  
  user_content = safe_string user_content

  paragraphs = user_content.split(/(?:\r?\n)/g)
  if paragraphs.length < 2
    WRAPPER = SPAN
  else 
    WRAPPER = P

  for para,pidx in paragraphs
    WRAPPER 
      key: "para-#{pidx}"

      # now split around all links
      for text,idx in para.split '(*-&)'
        if text.substring(0,5) == 'link:'
          A key: idx, href: text.substring(5, text.length), target: '_blank',
            text.substring(5, text.length)
        else  
          SPAN key: idx, text

      if append && pidx == paragraphs.length - 1
        append

# Computes the width of some text given some styles empirically
width_cache = {}
window.widthWhenRendered = (str, style) -> 
  # This DOM manipulation is relatively expensive, so cache results
  key = JSON.stringify _.extend({str: str}, style)
  if key not of width_cache
    style.display ?= 'inline-block'

    el = document.createElement 'span'
    el.id = "width_test"
    el.style.setProperty 'visibility', 'hidden'
    el.innerHTML = "<span>#{str}</span>"

    parent = document.getElementById('content')
    parent.appendChild el
    $$.setStyles "#width_test", style
    width = $$.width el
    parent.removeChild(el)

    width_cache[key] = width
  width_cache[key]



height_cache = {}
window.heightWhenRendered = (str, style) -> 
  # This DOM manipulation is relatively expensive, so cache results
  key = JSON.stringify _.extend({str: str}, style)
  if key not of height_cache
    el = document.createElement 'div'
    el.id = "height_test"
    el.style.setProperty 'visibility', 'hidden'
    el.innerHTML = "<span>#{str}</span>"

    parent = document.getElementById('content')
    parent.appendChild el
    $$.setStyles "#height_test", style
    height = $$.height el
    parent.removeChild(el)

    height_cache[key] = height
  height_cache[key]





# Computes the width/height of some text given some styles
size_cache = {}
window.sizeWhenRendered = (str, style) -> 
  main = document.getElementById('content')

  return {width: 0, height: 0} if !main

  style ||= {}
  # This DOM manipulation is relatively expensive, so cache results
  style.str = str
  key = JSON.stringify style
  delete style.str

  if key not of size_cache
    style.display ||= 'inline-block'

    test = document.createElement("div")
    test.innerHTML = "<div>#{str}</div>"
    for k,v of style

      key = k.replace(/([A-Z])/g, '-$1').toLowerCase()
      if key in ['font-size', 'max-width', 'max-height']
        test.style[key] = "#{v}px"
      else 
        test.style[key] = v

    main.appendChild test 
    h = test.offsetHeight
    w = test.offsetWidth
    main.removeChild test

    size_cache[key] = 
      width: w
      height: h

  size_cache[key]



# maps an opinion stance in [-1, 1] to a pixel value [0, width]
window.translateStanceToPixelX = (stance, width) -> (stance + 1) / 2 * width

# Maps a pixel value [0, width] to an opinion stance in [-1, 1] 
window.translatePixelXToStance = (pixel_x, width) -> 2 * (pixel_x / width) - 1


# Checks this node and ancestors whether check holds true
window.closest = (node, check) -> 
  if !node || node == document
    false
  else 
    check(node) || closest(node.parentNode, check)


window.location_origin = ->
  if !window.location.origin
    "#{window.location.protocol}//#{window.location.hostname}#{if window.location.port then ':' + window.location.port else ''}"
  else 
    window.location.origin


##############################
## Styles
############

window.focus_color = -> focus_blue

## CSS functions

# Mixin for mediaquery for retina screens. 
# Adapted from https://gist.github.com/ddemaree/5470343
window.css = {}

css.crossbrowserify = (styles) -> styles # legacy method now no-op-ing

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

window.header_font = ->
  customization('header_font') or customization('font')

window.mono_font = ->
  customization('mono_font') or customization('font')


window.responsive_css_rule = ({min_size, max_size, min_vw, max_vw}) -> 

  XX = min_vw / 100
  YY = 100 * (max_size - min_size) / (max_vw - min_vw)
  ZZ = min_size

  "clamp(#{min_size}px, calc(#{ZZ}px + ((1vw - #{XX}px) * #{YY})), #{max_size}px)"






# from https://gist.github.com/mathewbyrne/1280286
window.slugify = (text) -> 
  slug = text.toString().toLowerCase()
    .replace(/\s+/g, '-')           # Replace spaces with -
    .replace(/[^a-zA-Z0-9_\u3400-\u9FBF\s-]/g, '') # Remove all non-word chars (modification for chinese chars)
    .replace(/\-\-+/g, '-')         # Replace multiple - with single -
    .replace(/^-+/, '')             # Trim - from start of text
    .replace(/-+$/, '')             # Trim - from end of text

  if text?.length > 0 && slug?.length == 0 
    slug = md5 text 

  slug


# only play videos when they're in the viewport
videos_viewport_status = {}
window.play_videos_when_in_viewport = (parent_el, args) ->
  {play_only_topmost_video} = (args or {})
  videos = parent_el.querySelectorAll('video[autoplay]:not([data-initialized])')

  video_id = (video) ->
    video.getElementsByTagName("source")[0].src

  play_or_pause_after_event = -> 
    play_rest = true
    for video in videos 
      continue if video.readyState < 1
      should_play = !document.hidden && videos_viewport_status[video_id(video)]

      if should_play && play_rest
        video.play()
        if play_only_topmost_video
          play_rest = false
      else 
        video.pause()


  document.addEventListener 'visibilitychange', play_or_pause_after_event

  observe_video = (video) ->

    id = video_id(video)

    video.setAttribute 'data-initialized', "" 
    video.setAttribute 'playsinline', ""   

    video.addEventListener "loadstart", (e) ->
      video.classList.add 'loading'
      if video.hasAttribute 'controls'
        video.setAttribute 'data-controls', ""
      if !video.hasAttribute('poster')
        video.setAttribute 'controls', ""

    video.addEventListener 'loadeddata', (e) ->
      if video.readyState >= 1
        video.classList.remove 'loading'
        if !video.hasAttribute 'data-controls'
          video.removeAttribute 'controls'
        eligible_to_play = null

        observer_options = 
          root: null
          threshold: [1.0]

        observer = new IntersectionObserver (entries) ->
          entries.forEach (entry) ->
            if !entry.isIntersecting
              videos_viewport_status[id] = false
            else
              videos_viewport_status[id] = true

            play_or_pause_after_event()
        , observer_options

        observer.observe video



  for video in videos
    observe_video video






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


#content .fa {
  font-family: FontAwesome;  
}

#content, body, html, .full_height {
  height: 100%;
}

button {
  line-height: 1.4;
}
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
  box-sizing: border-box; 
}
.goog-te-gadget-simple .goog-te-menu-value span {
  font-weight: 400;
}
a {
  color: inherit;
  cursor: pointer;
  text-decoration: underline; 
  font-weight: 700;}
  a:focus {
  }
  a:active {
  }  
  a img {
    border: none; }

:focus {
}
.button, button, input[type='submit'] {
  cursor: pointer;
  text-align: center; 
  font-size: inherit;
} .button:focus, button:focus, input[type='submit']:focus {
} .button:active:focus, button:active:focus, input[type='submit']:active:focus{
}

button.like_link, input[type='submit'].like_link {
  background: none;
  border: none;
  text-decoration: underline;
  padding: 0px;
}

.btn {
  color: white;
  border: 0;
  font-weight: 700;
  padding: .325rem 1.5rem .4rem;
  line-height: 1.5;
  text-align: center;
  text-decoration: none;
  vertical-align: middle;
  cursor: pointer;
  user-select: none;
  -moz-user-select: none;
  -webkit-user-select: none;
  -ms-user-select: none;

  border-radius: .25rem;
  transition: color .15s ease-in-out,background-color .15s ease-in-out,border-color .15s ease-in-out,box-shadow .15s ease-in-out,-webkit-box-shadow .15s ease-in-out;
  margin: 0;
  background-color: #{focus_blue}; 
} .btn[disabled="true"], .btn[disabled] {
  cursor: default;
  opacity: .5;
}


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

html[lang='cs'] body, html[lang='cs'] input, html[lang='cs'] button, html[lang='cs'] textarea {
  font-family: Helvetica, Verdana, Arial, 'Lucida Grande', 'Lucida Sans Unicode', sans-serif; }


input[type="checkbox"], input[type="radio"], button, a {
  cursor: pointer;
}

input[type="checkbox"].bigger, input[type="radio"].bigger {
  transform: scale(1.5) translate(20%,0);
  font-size: 24px;
}

.hidden {
  position:absolute;
  left:-10000px;
  top:auto;
  width:1px;
  height:1px;
  overflow:hidden;}

a.skip:active, 
a.skip:focus, 
a.skip:hover {
    position: fixed;
    left: 0; 
    top: 0;
    width: auto; 
    height: auto; 
    overflow: visible; 
}


.content {
  position: relative;
  font-size: 16px;
  color: black;
  min-height: 100%; 
  font-weight: 400;

  background-color: #ffffff;

}


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
  color: white;
  font-size: 29px;
  margin-top: 14px;
  border: none;
  padding: 8px 36px; }

button.disabled {
  background-color: #eeeeee;
  color: #cccccc;
  box-shadow: none;
  border: none;
  cursor: wait; }

.primary_cancel_button {
  color: #888888;
  margin-top: 0.5em; }

.cancel_opinion_button {
  float: right;
  background: transparent;
  border: none;
  margin-top: 0.5em; }

button.primary_button, input[type='submit'] {
  display: inline-block; }

select.unstyled:not([multiple]){
    -webkit-appearance:none;
    -moz-appearance:none;
    background-position:right 50%;
    background-repeat:no-repeat;
    background-image:url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA4AAAAMCAYAAABSgIzaAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyJpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMC1jMDYwIDYxLjEzNDc3NywgMjAxMC8wMi8xMi0xNzozMjowMCAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNSBNYWNpbnRvc2giIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6NDZFNDEwNjlGNzFEMTFFMkJEQ0VDRTM1N0RCMzMyMkIiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6NDZFNDEwNkFGNzFEMTFFMkJEQ0VDRTM1N0RCMzMyMkIiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDo0NkU0MTA2N0Y3MUQxMUUyQkRDRUNFMzU3REIzMzIyQiIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDo0NkU0MTA2OEY3MUQxMUUyQkRDRUNFMzU3REIzMzIyQiIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PuGsgwQAAAA5SURBVHjaYvz//z8DOYCJgUxAf42MQIzTk0D/M+KzkRGPoQSdykiKJrBGpOhgJFYTWNEIiEeAAAMAzNENEOH+do8AAAAASUVORK5CYII=);
    padding: .5em;
    padding-right:1.5em;
    border-radius: 16px;
}

"""
