####
# Manages the browser window location by keeping the window history in sync
# with the url & query params stored on statebus at 'location'. 
#
# Also responsible for initializing location to the 
# correct value of window location on initial page load. 
#
# Assumes html5 pushstate history interface available. Make sure to use a 
# polyfill to support non-pushstate compatible browsers, such as 
# https://github.com/devote/HTML5-History-API 
#
# Defines a location-aware react link.


######
# Public API

####
# loadPage
#
# Convenience method for updating the browser window location. 
# Optionally pass query_params as a separate object. 

window.loadPage = (url, query_params) ->
  loc = fetch('location')
  loc.query_params = query_params or {}

  # if the url has query parameters, parse and merge them into params
  if url.indexOf('?') > -1
    [url, query_params] = url.split('?')

    for query_param in query_params.split('&')
      query_param = query_param.split('=')
      if query_param.length == 2
        loc.query_params[query_param[0]] = query_param[1]

  loc.url = url
  save loc

######
# A
#
# History-aware link
# Limitation: if an absolute url is specified as the href, 
# it will reload the page, even if the link is internal to this site
old_A = A
window.A = React.createClass
  render : -> 

    props = @props
    if @props.href
      _onclick = @props.onClick or (-> null)
      @props.onClick = (event) => 
        href = @getDOMNode().getAttribute('href') 
                  # use getAttribute rather than .href so we 
                  # can easily check relative vs absolute url
        
        is_external_link = href.indexOf('//') > -1
        opened_in_new_tab = event.altKey || 
                             event.ctrlKey || 
                             event.metaKey || 
                             event.shiftKey

        # Allow shift+click for new tabs, etc.
        if !is_external_link && !opened_in_new_tab
          event.preventDefault()
          loadPage href
          _onclick event
          return false
        else
          _onclick event


    old_A props, props.children

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
        history.pushState loc.query_params, title, new_location

      @last_location = new_location

      writeToLog
        what: 'changing url',
        where: loc.url


    SPAN null

relativeURLFromLocation = -> 
  # location.search returns query parameters
  "#{location.pathname}#{location.search}#{location.hash}"

relativeURLFromStatebus = ->  
  loc = fetch 'location'

  relative_url = loc.url 
  if _.keys(loc.query_params).length > 0
    query_params = ("#{k}=#{v}" for own k,v of loc.query_params)
    relative_url += "?#{query_params.join('&')}" 
  relative_url


##########
## Internal

# for html5 history polyfill
location = window.history.location || window.location

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


