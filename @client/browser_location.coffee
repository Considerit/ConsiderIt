####
# Manages the browser window location by keeping the window history in sync
# with the url & query params stored on statebus at 'location'. 
#
# Also responsible for initializing location to the 
# correct value of window location on initial page load. 
#
# Defines a location-aware react link.
#
# Assumes html5 pushstate history interface available. Make sure to use a 
# polyfill to support non-pushstate compatible browsers, such as 
# https://github.com/devote/HTML5-History-API 
require './vendor/html5-history-polyfill'
require './shared'
require './browser_hacks'

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

  # ...and parse anchors
  hash = ''
  if url.indexOf('#') > -1
    [url, hash] = url.split('#')
    url = '/' if url == ''

    # When loading a page with a hash, we need to scroll the page
    # to proper element represented by that id. This is hard to 
    # represent in Statebus, as it is more of an event than state.
    # We'll set seek_to_hash here, then it will get set to null 
    # after it is processed. 
    loc.seek_to_hash = true

  loc.url = url
  loc.hash = hash

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
      @_onclick = @props.onClick or (-> null)

      if browser.is_mobile
        @props.onTouchEnd = (e) => 
          # don't follow the link if the user is in the middle of swipping
          if !is_swipping
            @handleClick(e)

        if browser.is_android_browser
          @props.onClick = (e) -> e.preventDefault(); e.stopPropagation()

      else
        @props.onClick = @handleClick


    old_A props, props.children

  handleClick: (event) -> 
    node = @getDOMNode()
    href = node.getAttribute('href') 
              # use getAttribute rather than .href so we 
              # can easily check relative vs absolute url
    
    is_external_link = href.indexOf('//') > -1
    is_mailto = href.toLowerCase().indexOf('mailto') > -1

    opened_in_new_tab = event.altKey || 
                         event.ctrlKey || 
                         event.metaKey || 
                         event.shiftKey

    # Allow shift+click for new tabs, etc.
    if !is_external_link && !opened_in_new_tab && !is_mailto \
       && !node.getAttribute('data-nojax')

      event.preventDefault()
      event.stopPropagation()
      loadPage href
      @_onclick event

      # When we navigate to another internal page, we typically want the 
      # page to be scrolled to the top of the new page. The programmer can
      # set "data-no-scroll" on the link if they wish to prevent this 
      # behavior.
      if !@getDOMNode().getAttribute('data-no-scroll')
        window.scrollTo(0, 0)
                      
      return false
    else
      @_onclick event

#####
# BrowserLocation
#
# Responds to changes in location, keeping the browser history up to date. 
# Also updates the window title if it has been updated via statebus. 

window.BrowserLocation = ReactiveComponent
  displayName: 'BrowserLocation'

  render : -> 
    loc = fetch 'location'
    doc = fetch 'document'

    # Update the window title if it has changed
    title = doc.title or document.title
    if doc.title && document.title != doc.title
      document.title = doc.title

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

  componentDidUpdate : -> 

    loc = fetch 'location'
    if loc.seek_to_hash 
      loc.seek_to_hash = false
      save loc

      # TODO: This doesn't work right now on initial page load
      #       in Chrome & Safari for a return visitor. The 
      #       browser's remember scroll gets imposed after this 
      #       runs, and overrides it. 
      el = document.querySelector("##{loc.hash}")
      if el
        # If there are docked elements, we want to scroll a bit 
        # before the element so that the docked elements don't 
        # obscure the section headings
        docks = fetch('docking_station')
        seek_below = docks.y_stack or 50
        $(window).scrollTop getCoords(el).top - seek_below

relativeURLFromLocation = -> 
  # location.search returns query parameters

  # fix url encoding of /
  search = location.search?.replace(/\%2[fF]/g, '/')
  "#{location.pathname}#{search}#{location.hash}"

relativeURLFromStatebus = ->  
  loc = fetch 'location'

  relative_url = loc.url 
  if _.keys(loc.query_params).length > 0
    query_params = ("#{k}=#{v}" for own k,v of loc.query_params)
    relative_url += "?#{query_params.join('&')}" 
  if loc.hash?.length > 0
    relative_url += "##{loc.hash}"
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


