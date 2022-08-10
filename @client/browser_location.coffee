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
#require './vendor/html5-history-polyfill'
require './shared'
require './browser_hacks'

######
# Public API


parseURL = (url) ->
  parser = document.createElement('a')
  parser.href = url

  pathname = parser.pathname or '/'
  if pathname[0] != '/'
    pathname = "/#{pathname}"
  searchObject = {}

  alt_search = new URLSearchParams(parser.search)

  queries = parser.search.replace(/^\?/, '').split('&')  
  i = 0
  while i < queries.length
    if queries[i].length > 0
      split = queries[i].split('=')
      searchObject[split[0]] = alt_search.get(split[0])
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

####
# loadPage
#
# Convenience method for updating the browser window location. 
# Optionally pass query_params as a separate object. 

window.loadPage = (url, query_params) ->
  loc = fetch('location')
  loc.query_params = query_params or {}

  url_parts = parseURL "#{location_origin()}#{url}" 
  # if the url has query parameters, parse and merge them into params

  for k,v of url_parts.searchObject when k.length > 0
    loc.query_params[decodeURIComponent(k)] = decodeURIComponent(v)

  # loc.query_params = url_parts.searchObject
  delete loc.query_params.u if loc.query_params.u
  delete loc.query_params.t if loc.query_params.t

  # ...and parse anchors
  hash = url_parts.hash
  if hash && hash.length > 0 
    hash = hash.substring(1)
    # When loading a page with a hash, we need to scroll the page
    # to proper element represented by that id. This is hard to 
    # represent in Statebus, as it is more of an event than state.
    # We'll set seek_to_hash here, then it will get set to null 
    # after it is processed. 
    loc.seek_to_hash = hash

  loc.url = decodeURIComponent(url_parts.pathname)
  loc.hash = hash

  save loc

######
# A
#
# History-aware link
# Limitation: if an absolute url is specified as the href, 
# it will reload the page, even if the link is internal to this site

old_A = A
window.is_swipping = false
window.A = React.createFactory createReactClass
  displayName: 'modified_A'
  render : -> 

    props = _.extend {}, @props
    if props.href
      @_onclick = props.onClick or (-> null)

      if browser.is_mobile
        props.onTouchEnd = (e) => 
          # don't follow the link if the user is in the middle of swipping
          if !is_swipping
            @handleClick(e)

        if browser.is_android_browser
          props.onClick = (e) -> e.preventDefault(); e.stopPropagation()

      else
        props.onClick = @handleClick


    old_A props, props.children

  handleClick: (event) -> 
    node = ReactDOM.findDOMNode(@)
    no_scroll = node.getAttribute('data-no-scroll')
    href = node.getAttribute('href') 
              # use getAttribute rather than .href so we 
              # can easily check relative vs absolute url
    
    is_external_link = href.indexOf('//') > -1 || @props.treat_as_external_link
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

      setTimeout =>
        # When we navigate to another internal page, we typically want the 
        # page to be scrolled to the top of the new page. The programmer can
        # set "data-no-scroll" on the link if they wish to prevent this 
        # behavior.
        if !no_scroll || no_scroll == 'false'
          window.scrollTo(0, 0)
      , 1
                      
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


      int = setInterval ->
        el = null 
        try 
          el = document.querySelector("##{loc.hash}")
        catch e 
          noop = 1

        el ||= document.querySelector("[name=\"#{loc.hash}\"]") || document.querySelector("#p#{loc.hash}")


        if el
          # If there are docked elements, we want to scroll a bit 
          # before the element so that the docked elements don't 
          # obscure the section headings
          docks = fetch('docking_station')
          seek_below = docks.y_stack or 50
          
          window.scrollTo 0, getCoords(el).top - seek_below

          el.focus()
          clearInterval int 
      , 100

relativeURLFromLocation = -> 
  # location.search returns query parameters


  # fix url encoding of /
  search = location.search?.replace(/\%2[fF]/g, '/')
  loc = location.pathname?.replace(/\%20/g, ' ')

  "#{loc}#{search}#{location.hash}"

relativeURLFromStatebus = ->  
  loc = fetch 'location'

  relative_url = loc.url 
  if _.keys(loc.query_params).length > 0
    query_params = ("#{k}=#{encodeURIComponent(v)}" for own k,v of loc.query_params)
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


