####
# Manages the browser window location
#
# The url and url params are stored on statebus at key 'location'. A 
# convenience method for manipulating location, loadPage, is defined
# below.
#
# BrowserLocation will respond to changes in location, keeping the 
# browser history up to date. We're still using backbone for managing
# browser specific location updates, but now only a very small slice.
#
# Finally, this file is responsible for initializing location to the 
# correct value of window location on initial page load. 


######
# Public API
#
# loadPage
#
# Helper method for updating the browser window location. 
# Optionally pass url_parameters as a separate object. 
window.loadPage = (url, url_params) ->
  loc = fetch('location')
  loc.params = url_params or {}

  # insert anchor for non-push state enabled browsers
  if !Backbone.history?._hasPushState && url.indexOf('#') > -1
    url = "/" + url.substring(url.indexOf('#') + 1, url.length)

  # if the url has url params, parse and merge them into params
  if url.indexOf('?') > -1
    [url, search] = url.split('?')
    _.extend loc.params, parse_url_params(search)

  loc.url = url

  save loc


## Private
window.BrowserLocation = ReactiveComponent
  displayName: 'BrowserLocation'

  render : -> 
    loc = fetch 'location'

    new_location = loc.url 
    if _.keys(loc.params).length > 0
      params = ("#{k}=#{v}" for own k,v of loc.params)
      new_location += "?#{params.join('&')}" 

    current_loc = "#{window.location.pathname}#{window.location.search}"
    if current_loc != new_location 
      if Backbone.history?._hasPushState
        Backbone.history.navigate new_location
      else
        hash_url = loc.url
        if loc.url[0] = '/'
          hash_url = "/##{hash_url.substring(1, hash_url.length)}"
        Backbone.history.navigate hash_url

      writeToLog
        what: 'loaded page',
        where: loc.url

      ######
      # Temporary technique for handling resetting root state when switching between
      # routes. TODO: more elegant approach
      root = fetch('root')
      if root.auth
        root.auth = null
        save root

      hist = fetch('histogram')
      if hist.selected_opinion || hist.selected_opinions || hist.selected_opinion_value
        hist.selected_opinion = hist.selected_opinions = hist.selected_opinion_value = null
        save hist
      #######

    SPAN null

parse_url_params = (search) -> 
  params = {}
  if search[0] == '?'
    search = search.substring(1, search.length)

  for url_param in search.split('&')
    url_param = url_param.split('=')
    if url_param.length == 2
      params[url_param[0]] = url_param[1]
  params

#####
# Initializes the location state based on browser url when page is loaded
params = {}
search = window.location.search
if search?.length > 0 
  params = parse_url_params(search)

loadPage "#{window.location.pathname}#{window.location.hash}", params
#####

# We're still using Backbone for managing the nitty-gritty of browser-specific
# window locations
$( -> 
  Backbone.history.start {pushState: true}
)