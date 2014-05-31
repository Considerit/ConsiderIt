casper = require('casper').create()
casper.options.waitTimeout = 15000

valence = casper.cli.get('valence').toLowerCase()
nutshell = casper.cli.get('nutshell')
body = casper.cli.get('body')
stance = casper.cli.get('stance').toLowerCase()
username = casper.cli.get('user')
proposal_id = casper.cli.get('proposal_id')
group = casper.cli.get('group')
is_point = casper.cli.get('is_point')
host = casper.cli.get('host')


getLoggedInUserid = ->
  casper.getElementAttribute '.user-options [data-role="user"]', 'data-id'


logout = ->
  casper.then ->
    if casper.exists '[action="logout"]'
      casper.echo "Action: starting to log out"
      casper.thenClick '[action="logout"]'
      casper.waitForSelector '[action="login"]', ->
        casper.echo 'Action: logged out'

createAccount = (email, username, group) ->
  password = '1234567890'
  logout()

  casper.waitUntilVisible '[action="login"]', ->
    casper.echo "Action: starting to create an account #{email}"
  casper.thenClick '[action="login"]'
  casper.waitUntilVisible 'input#user_email'
  casper.thenClick 'input#user_email', ->
    casper.sendKeys 'input#user_email', email
  casper.thenClick 'input#password_none'
  casper.thenClick '[action="create-account"]'
  casper.waitUntilVisible 'input#user_name', ->
    casper.sendKeys 'input#user_name', username
    casper.sendKeys 'input#user_password', password
    #this prevents weird casper/phantomjs error
    casper.capture "lib/tasks/client_data/screens/#{group}.png"    

    casper.thenClick 'input#pledge1'
    casper.thenClick 'input#pledge2'

    #add picture upload!
    casper.then ->   
      casper.evaluate (filename) ->
        __utils__.findOne('#user_avatar[type="file"]').setAttribute('value', filename)
      , "lib/tasks/client_data/profiles/#{group}.png".toLowerCase()

      casper.page.uploadFile 'input#user_avatar[type="file"]', "lib/tasks/client_data/profiles/#{group}.png".toLowerCase()


    casper.thenClick '[action="paperwork_complete"]'

    casper.waitUntilVisible '.user-options-display', ->
      casper.echo "Action: created account #{email}"


waitUntilStateTransitioned = (state) ->
  casper.waitUntilVisible "[state='#{state}']"
  casper.waitWhileVisible '.transitioning'
  casper.wait 500


casper.start "http://#{host}/#{proposal_id}", ->

  waitUntilStateTransitioned 'crafting'

  casper.then -> 
    createAccount("#{username}@ghost.dev", username, group)
  
  # move the slider

  casper.thenEvaluate (stance) ->


    target = '.noUi-base'

    slider_position = $(target).offset().left
    if stance == 'support'
      slider_position += $(target).width() / 4
    else if stance == 'neutral'
      slider_position += $(target).width() / 2
    else if stance == 'oppose'
      slider_position += $(target).width() * .75

    event = document.createEvent("HTMLEvents")
    event.initEvent("mousedown", true, true)
    event.eventName = "mousedown"
    event.clientX = slider_position
    event.clientY = $(target).offset().top + 3
    $(target)[0].dispatchEvent(event)
  , stance

  # casper.wait 100, ->
  #   casper.capture "lib/tasks/client_data/screens/#{stance}-#{username}.png"


  if is_point
    # Contribute the point
    points_col = if valence == 'pro' then '.pros_on_decision_board' else '.cons_on_decision_board'


    casper.thenClick("#{points_col} [action='write-point']")

    casper.waitUntilVisible "#{points_col} .newpoint_form", ->
      @sendKeys "#{points_col} .newpoint_nutshell", nutshell
      if body && body.length > 0
        @sendKeys "#{points_col} .newpoint_description", body

      #this prevents weird casper/phantomjs error
      casper.capture "lib/tasks/client_data/screens/#{stance}-#{username}.png"
    , ->
      casper.echo '**** COULD NOT CREATE POINT ' + nutshell 

    casper.thenClick "#{points_col} [action='submit-point']"

    casper.waitUntilVisible "#{points_col} [data-role='point']"

  else
    # expand proper column
    points_col = if valence == 'pro' then '.pros_by_community' else '.cons_by_community'
    casper.then -> 
      #casper.echo "Exists? #{casper.exists(\"#{points_col} [action='expand-toggle']\")}"
      if casper.exists "#{points_col} [action='expand-toggle']"
        casper.thenClick "#{points_col} [action='expand-toggle']"
        casper.wait 300

    # find the point to which to add the comment
    casper.then -> 
      current_user = getLoggedInUserid()
      point_id = casper.evaluate (nutshell) -> 
        return $("[data-role='point'] .point_nutshell:contains('#{nutshell}')").closest('[data-role="point"]').attr('data-id')
      , nutshell

      # open the point
      casper.thenClick "[data-role='point'][data-id='#{point_id}'] .point_content" 
  
      casper.waitUntilVisible ".new_comment_body textarea"

      #comment the point
      casper.thenClick ".new_comment_body textarea", ->
        casper.sendKeys ".new_comment_body textarea", body
        #this prevents weird casper/phantomjs error
        casper.capture "lib/tasks/client_data/screens/#{stance}-#{username}.png"

      casper.wait 100
      casper.thenClick "[action='submit-comment']"

      casper.waitUntilVisible ".comment .avatar[data-id='#{current_user}']"

      # close the point
      casper.thenClick '.close_open_point'

  casper.then ->
    casper.capture "lib/tasks/client_data/screens/#{stance}-#{username}.png"


  casper.wait 100
  casper.thenClick '[action="submit-opinion"]'
  waitUntilStateTransitioned 'results'


casper.run ->
  casper.exit()
 