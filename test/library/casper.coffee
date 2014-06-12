fs = require('fs')
_ = require('../../node_modules/underscore')

casper.options.waitTimeout = 10000;

######################################################
## Custom Casper methods tailored for Consider.it
######################################################

_.extend casper, 

  # waits until transitions amongst considerit states are completed (e.g. results page)
  waitUntilStateTransitioned : (state, callback, timeout_callback = null) ->
    casper.waitUntilVisible "[data-state='#{state}']", null, timeout_callback
    casper.wait 100
    casper.waitWhileVisible '.transitioning', null, timeout_callback
    casper.wait 200, ->
      callback.call casper if callback


  getLoggedInUserid : ->
    @getElementAttribute '.user-options [data-role="user"]', 'data-id'


  # DRAG AND DROP NOT WORKING YET GIVEN CASPER AND PHANTOM LIMITATIONS
  #drag an element from a to b
  dragAndDrop : (draggable, target) ->
    from = casper.getElementBounds draggable
    to = casper.getElementBounds target

    casper.drag [from.left + from.width / 2, from.top + from.height / 2], [to.left + to.width / 2, to.top + to.height / 2]

  drag : (from, to) ->
    casper.capture "#{casper.cli.options.htmlout}/screen_captures/DRAG.png", 
      left: from[0]
      top: from[1]
      width: 100
      height: 100


    casper.capture "#{casper.cli.options.htmlout}/screen_captures/DROP.png", 
      left: to[0]
      top: to[1]
      width: 300
      height: 300

    casper.mouse.down from[0], from[1]
    casper.mouse.move to[0], to[1]
    casper.HTMLCapture '.reasons_region',
      caption: 'JUST BEFORE RELEASE!!!'
    casper.mouse.up to[0], to[1]

######################################################
## Processing Casper Events
######################################################

# Capture whenever a javascript error is encountered
casper.on "page.error", (msg, trace) -> 
  casper.writeHTML "<div class='javascript_error entry'>#{msg}</div>"

# Capture whenever a resource fails to download
casper.on "resource.error", (er) ->
  casper.writeHTML "<div class='resource_error entry'>Failed to load #{er.url}: #{er.errorCode} - #{er.errorString}</div>"

# Capture screens from all fails
casper.test.on "fail", (failure) ->
  casper.HTMLCapture 'body'

# Capture screens from timeouts from e.g. @waitUntilVisible
casper.options.onWaitTimeout = ->
  casper.HTMLCapture 'body'


#################################################################
## Patching for HTML output functionality to common casper methods
#################################################################

_.extend casper, 

  ## Takes a screenshot of the given selector and outputs results to HTML
  HTMLCapture : (selector = 'body', options = {}) ->
    options.sizes ?= [ [1200, 900] ]

    wrap = "<div class='screenshots entry'>"
    for [width, height] in options.sizes
      @viewport width, height
      fname = "#{Date.now()}-#{width}x#{height}.png"
      @captureSelector "#{casper.cli.options.htmlout}/screen_captures/#{fname}", selector
      wrap += "<a href='screen_captures/#{fname}'><img src='screen_captures/#{fname}'></a>"
    
    if options.caption?
      wrap += "<div class='capture_caption'>#{options.caption}</div>"      
    
    wrap += "</div>"

    casper.writeHTML wrap

  logStep : (message, style = 'COMMENT') -> 
    casper.writeHTML "<div class='step entry'>&#10095; #{message}</div>"
    casper.echo message, style

  logAction : (message, style = 'COMMENT') ->
    casper.writeHTML "<div class='action entry'>&#10095; #{message}</div>"    
    casper.echo message, style

  writeHTML : (html) ->
    f = casper.getHTMLOutput()
    f.write html
    f.close()

  getHTMLOutput : ->
    fs.open "#{casper.cli.options.htmlout}/index.html", 'a+'




casper.test._begin = casper.test.begin
casper.test._processAssertionResult = casper.test.processAssertionResult

_.extend casper.test, 
  begin : (args...) ->
    casper.writeHTML "<div class='test_suite_name'>#{args[0]}</div>"
    casper.test._begin.apply casper.test, args

  processAssertionResult : (result) -> 
    casper.test._processAssertionResult result
    
    if result.success
      result_class = 'success'
      status = "Passed"
    else if !result.success? 
      result_class = 'skip'
      status = "Skipped"
    else if !result.success
      result_class = 'failure'
      status = "FAILED!"
    
    wrap = "<div class='result_wrap #{result_class} entry'>\n"
    wrap += "<span class='result'>#{status}</span> <span class='message'>#{result.message}  (#{result.standard}) </span>\n"
    wrap += "</div>\n"

    casper.writeHTML wrap

    result
