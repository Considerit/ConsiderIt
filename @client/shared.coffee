require './responsive_vars'
require './color'


# Unfortunately, google makes it so there can only be one Google Translate Widget 
# rendered into a page. So we have to move around the same element, rather than 
# embed it nicely where we want. 
window.GoogleTranslate = ReactiveComponent
  displayName: 'GoogleTranslate'

  render: -> 
    loc = fetch 'location'
    homepage = loc.url == '/'
    style = if customization('google_translate_style') && homepage 
              customization('google_translate_style')
            else 
              _.defaults {}, @props.style, 
                textAlign: 'center'
                marginBottom: 10

    DIV 
      key: "google_translate_element_#{@local.key}"
      id: "google_translate_element_#{@local.key}"
      style: style

  insertTranslationWidget: -> 
    subdomain = fetch '/subdomain'
    new google.translate.TranslateElement {
        pageLanguage: subdomain.lang
        layout: google.translate.TranslateElement.InlineLayout.SIMPLE
        multilanguagePage: true
        # gaTrack: #{Rails.env.production?}
        # gaId: 'UA-55365750-2'
      }, "google_translate_element_#{@local.key}"

  componentDidMount: -> 

    @int = setInterval => 
      if google?.translate?.TranslateElement?
        @insertTranslationWidget()
        clearInterval @int 
    , 20

  componentWillUnmount: ->
    clearInterval @int


window.pad = (num, len) -> 
  str = num
  dec = str.split('.')
  i = 0 
  while i < len - dec[0].toString().length
    dec[0] = "0" + dec[0]
    i += 1

  dec[0] + if dec.length > 0 then '.' + dec[1] else ''


window.back_to_homepage_button = (style) -> 
  loc = fetch('location')
  homepage = loc.url == '/'

  hash = loc.url.split('/')[1].replace('-', '_')

  NAV 
    role: 'navigation'
    A
      className: 'back_to_homepage'
      title: 'back to homepage'
      key: 'back_to_homepage_button'
      href: "/##{hash}"
      style: _.defaults {}, style,
        fontSize: 43
        visibility: if homepage || !customization('has_homepage') then 'hidden' else 'visible'
        color: 'black'

      '<'


####
# Make the DIV, SPAN, etc.
for el of React.DOM
  window[el.toUpperCase()] = React.DOM[el]

window.styles = ""

window.TRANSITION_SPEED = 700   # Speed of transition from results to crafting (and vice versa) 

window.LIVE_UPDATE_INTERVAL = 3 * 60 * 1000

# live updating
setInterval ->
  dependent_keys = []
  proposals = false 
  for key of arest.components_4_key.hash
    if key[0] == '/' && arest.components_4_key.get(key).length > 0 && \
       !key.match(/\/(user|opinion|point|proposals)\//)

      if key.match(/\/proposal\//)
        proposals = true 

      else if key != '/current_user' || fetch('/current_user').logged_in
        arest.serverFetch(key)
        #console.log "FETCHING #{key}"
  if proposals 
    arest.serverFetch('/proposals')

, LIVE_UPDATE_INTERVAL 

window.POINT_MOUTH_WIDTH = 17



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
    right: offset.left + rect.width
    bottom: offset.top + rect.height


#### browser

# stored in public/images
window.asset = (name) -> 
  app = fetch('/application')

  if app.app?
    a = "#{app.asset_host or ''}/images/#{name}"
  else 
    a = "#{window.asset_host or ''}/images/#{name}"

  a

#####
# data 
window.opinionsForProposal = (proposal) ->       
  opinions = fetch(proposal).opinions || []
  opinions

window.get_all_clusters = ->
  proposals = fetch '/proposals'
  always_show = customization 'homepage_lists_to_always_show'
  all_clusters = ((p.cluster or 'Proposals').trim() for p in proposals.proposals)
  all_clusters = all_clusters.concat always_show
  all_clusters = _.uniq all_clusters
  all_clusters



newest_in_cluster_on_load = {}

window.clustered_proposals = -> 
  proposals = fetch '/proposals'
  homepage_list_order = customization 'homepage_list_order'

  # create clusters
  clusters = {}

  all_clusters = get_all_clusters()

  # By default sort proposals by the newest of the proposals.
  # But we'll only do this on page load, so that clusters don't move
  # around when someone adds a new proposal.
  if Object.keys(newest_in_cluster_on_load).length == 0
    for proposal in proposals.proposals 
      cluster = (proposal.cluster or 'Proposals').trim()
      time = (new Date(proposal.created_at).getTime())
      if !newest_in_cluster_on_load[cluster] || time > newest_in_cluster_on_load[cluster]
        newest_in_cluster_on_load[cluster] = time 

  for cluster in all_clusters
    sort = homepage_list_order.indexOf cluster
    if sort < 0 
      if newest_in_cluster_on_load[cluster]
        sort = homepage_list_order.length + ((new Date()).getTime() - newest_in_cluster_on_load[cluster])
      else 
        sort = 9999999999999

    clusters[cluster] = 
      key: "list/#{cluster}"
      name: cluster
      proposals: []
      list_is_archived: customization('list_is_archived', "list/#{cluster}")
      sort_order: sort

  for proposal in proposals.proposals 
    cluster = (proposal.cluster or 'Proposals').trim()
    clusters[cluster].proposals.push proposal

  # order
  ordered_clusters = _.values clusters 
  ordered_clusters.sort (a,b) -> a.sort_order - b.sort_order
  ordered_clusters 

window.clustered_proposals_with_tabs = -> 
  all_clusters = clustered_proposals()
  homepage_tabs = fetch 'homepage_tabs'
  if homepage_tabs.filter?
    to_remove = []
    for cluster, index in all_clusters or []
      cluster_key = "list/#{cluster.name}"

      fails_filter = homepage_tabs.filter? && (homepage_tabs.clusters != '*' && !(cluster.name in homepage_tabs.clusters) )
      if fails_filter && ('*' in homepage_tabs.clusters)
        in_others = []
        for filter, clusters of customization('homepage_tabs')
          in_others = in_others.concat clusters 

        fails_filter &&= cluster.name in in_others
      if fails_filter
        to_remove.push cluster 

    all_clusters = _.difference all_clusters, to_remove
  all_clusters


######
# Expands a key like 'slider' to one that is namespaced to a parent object, 
# like the current proposal. Will return a local key like 'proposal/345/slider' 
window.namespaced_key = (base_key, base_object) ->
  namespace_key = fetch(base_object).key 

  # don't store this on the server
  if namespace_key[0] == '/'
    namespace_key = namespace_key.substring(1, namespace_key.length)
  
  "#{namespace_key}_#{base_key}"

window.proposal_url = (proposal) =>
  # The special thing about this function is that it only links to
  # "?results=true" if the proposal has an opinion.

  proposal = fetch proposal
  result = '/' + proposal.slug
  subdomain = fetch('/subdomain') 

  if subdomain.name == 'homepage'
    subdomain = fetch("/subdomain/#{proposal.subdomain_id}")
    result = "https://#{subdomain.host_with_port}" + result

  if TWO_COL() || (!customization('show_crafting_page_first', proposal) || !proposal.active ) \
     || (!customization('discussion_enabled', proposal))

    result += '?results=true'

  return result

window.isNeutralOpinion = (stance) -> 
  return Math.abs(stance) < 0.05

  

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

  return if isNaN(day_diff) || day_diff < 0

  # TODO: pluralize properly (e.g. 1 days ago, 1 weeks ago...)
  r = day_diff == 0 && (
    diff < 60 && "just now" || 
    diff < 120 && "1 minute ago" || 
    diff < 3600 && Math.floor(diff / 60) + " minutes ago" || 
                              diff < 7200 && "1 hour ago" || 
                              diff < 86400 && Math.floor(diff / 3600) + " hours ago") || 
                              day_diff == 1 && "Yesterday" || 
                              day_diff < 7 && day_diff + " days ago" || 
                              day_diff < 31 && Math.ceil(day_diff / 7) + " weeks ago" ||
                              "#{date.getMonth() + 1}/#{date.getDay() + 1}/#{date.getFullYear()}"

  r = r.replace('1 days ago', '1 day ago').replace('1 weeks ago', '1 week ago').replace('1 years ago', '1 year ago')
  r


window.shorten = (str, max_length) ->
  max_length ||= 70
  "#{str.substring(0, max_length)}#{if str.length > max_length then '...' else ''}"

window.inRange = (val, min, max) ->
  return val <= max && val >= min

window.capitalize = (string) -> string.charAt(0).toUpperCase() + string.substring(1)
window.capitalize_each_word = (str) -> str.replace /\b\w/g, (l) -> l.toUpperCase()

window.L = window.LOADING_INDICATOR = DIV null, 'Loading...'


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


window.splitParagraphs = (user_content, append) ->
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
      [\-A-Z0-9+\u0026\u2019@#/%?=()\[\]\-\$&\*~_|!:,.;']* # Valid URL characters (any number of times)
      [\-A-Z0-9+\u0026@#/%=~()_|] # String must end in a valid URL character
    )
  ///gi
  user_content = user_content.replace(hyperlink_pattern, "$1(*-&)link:$2(*-&)")
  paragraphs = user_content.split(/(?:\r?\n)/g)

  for para,pidx in paragraphs
    P key: "para-#{pidx}", 
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
    _.defaults style, 
      display: 'inline-block'
    $el = $("<span id='width_test'><span>#{str}</span></span>").css(style)
    $('#content').append($el)
    width = $('#width_test span').width()
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

window.parseURL = (url) ->
  parser = document.createElement('a')
  parser.href = url

  pathname = parser.pathname or '/'
  if pathname[0] != '/'
    pathname = "/#{pathname}"
  searchObject = {}
  queries = parser.search.replace(/^\?/, '').split('&')
  i = 0
  while i < queries.length
    if queries[i].length > 0
      split = queries[i].split('=')
      searchObject[split[0]] = split[1]
    i++

  {
    protocol: parser.protocol
    host: parser.host
    hostname: parser.hostname
    port: parser.port
    pathname: pathname
    search: parser.search
    searchObject: searchObject
    hash: parser.hash
  }



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

  if props.transformOrigin
    for prefix in prefixes
      props["#{prefix}transform-origin"] = props.transform

  if props.flex 
    for prefix in prefixes
      props["#{prefix}flex"] = props.flex

  if props.flexDirection
    for prefix in prefixes
      props["#{prefix}flex-direction"] = props.flexDirection

  if props.justifyContent
    for prefix in prefixes
      props["#{prefix}justify-content"] = props.justifyContent


  if props.display == 'flex'
    props.display = 'display: table-cell; -webkit-box; display: -moz-box; display: -ms-flexbox; display: -webkit-flex; display: flex'

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


# from https://gist.github.com/mathewbyrne/1280286
window.slugify = (text) -> 
  text.toString().toLowerCase()
    .replace(/\s+/g, '-')           # Replace spaces with -
    .replace(/[^\w\-]+/g, '')       # Remove all non-word chars
    .replace(/\-\-+/g, '-')         # Replace multiple - with single -
    .replace(/^-+/, '')             # Trim - from start of text
    .replace(/-+$/, '')             # Trim - from end of text




## CSS reset
focus_shadow = 'inset 0 0 2px rgba(0,0,0,.3), 0 0 2px rgba(0,0,0,.3)'
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

body, html {
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
  box-sizing: border-box; }

a {
  color: inherit;
  cursor: pointer;
  text-decoration: none; }
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
  min-height: 100%; }


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
