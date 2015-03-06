####
# Manages the browser window location by keeping the window history in sync
# with the url & params stored on statebus at 'location'. 
#
# Also responsible for initializing location to the 
# correct value of window location on initial page load. 
#
# Assumes html5 pushstate history interface available. Make sure to use a 
# polyfill to support non-pushstate compatible browsers, such as 
# https://github.com/devote/HTML5-History-API 

######
# Public API
#
# loadPage
#
# Convenience method for updating the browser window location. 
# Optionally pass url_parameters as a separate object. 
window.loadPage = (url, url_params) ->
  loc = fetch('location')
  loc.params = url_params or {}

  # if the url has search params, parse and merge them into params
  if url.indexOf('?') > -1
    [url, search] = url.split('?')

    for url_param in search.split('&')
      url_param = url_param.split('=')
      if url_param.length == 2
        loc.params[url_param[0]] = url_param[1]

  loc.url = url
  save loc


##########
## Internal

# for html5 history polyfill
location = window.history.location || window.location


#####
# BrowserLocation
#
# Responds to changes in location, keeping the browser history up to date. 
# Also updates the window title if it has been updated via statebus. 

window.BrowserLocation = ReactiveComponent
  displayName: 'BrowserLocation'

  render : -> 
    loc = fetch 'location'

    # Update the window title if it has changed
    title = loc.title or document.title
    if loc.title && document.title != loc.title
      document.title = loc.title

    # Respond to a location change
    new_location = relativeURLFromStatebus()
    if @last_location != new_location 

      # update browser history if it hasn't already been updated
      if relativeURLFromLocation() != new_location
        history.pushState loc.params, title, new_location

      @last_location = new_location

      writeToLog
        what: 'changing url',
        where: loc.url

      ######
      # Temporary technique for handling resetting root state when switching 
      # between routes. TODO: more elegant approach
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

relativeURLFromLocation = -> 
  "#{location.pathname}#{location.search}#{location.hash}"

relativeURLFromStatebus = ->  
  loc = fetch 'location'

  relative_url = loc.url 
  if _.keys(loc.params).length > 0
    params = ("#{k}=#{v}" for own k,v of loc.params)
    relative_url += "?#{params.join('&')}" 
  relative_url


#####
# Update statebus location when browser back or forward button pressed

[addEventListener, popstate_event] = if window.addEventListener 
                                       ['addEventListener', 'popstate'] 
                                     else 
                                       ['attachEvent', 'onpopstate']

window[addEventListener] popstate_event, (ev) -> 
  loadPage relativeURLFromLocation()

# Initialize location state when page is first loaded.
loadPage relativeURLFromLocation()


