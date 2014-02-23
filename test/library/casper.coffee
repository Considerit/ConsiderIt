fs = require('fs')
_ = require('underscore')

actions = require('./actions')

######################################################
## Custom Casper methods tailored for Consider.it
######################################################

_.extend casper, 

  # loops through the given test (callback), first when logged out and second when logged in
  executeLoggedInAndLoggedOut : (location, callback) ->
    casper.start location

    casper.wait 5000, -> 
      actions.logout()

    casper.then ->
      callback.call casper, false # run tests while not logged in

    casper.thenOpen(location).waitUntilVisible '#l_wrap', ->
      if casper.exists '[action="login"]'
        casper.then ->
          id = Math.floor((Math.random()*100000)+1)
          actions.createAccount "Testy #{id}", "testy_mctesttest_#{id}@testing.dev", '123124124243'

        casper.wait 2500, ->
          callback.call casper, true # run tests while logged in
      else
        callback.call casper, true

  # waits until transitions amongst considerit states are completed (e.g. results page)
  waitUntilStateTransitioned : (state, callback) ->
    casper.waitUntilVisible "[state='#{state}']", ->
      casper.waitWhileVisible '.transitioning', ->
        casper.wait 200, ->
          callback.call casper


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

  HTMLStep : (message) -> 
    casper.writeHTML "<div class='step entry'>&#10095; #{message}</div>"
    casper.echo message, 'COMMENT'


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
