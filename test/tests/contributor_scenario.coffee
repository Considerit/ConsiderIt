require('../library/casper')
require('../library/asserts')
actions = require('../library/actions')
_ = require('underscore')

###

Tests a prolific, crazy user crafting their opinion.  

They add points, edit them and delete them! They include points then remove them. They craft an opinion comprised of
points they authored, points adopted from the community and specify a slider. Before saving, they go the homepage. They go
to the results page. They go back to the crafting page to find their opinion intact. 

Then they save their opinion. Their opinion is reflected in the histogram. They update their opinion, and note that it was
changed in their histogram. They refresh the page and see that their opinion is still there. They logout and see their points
contributed to the community points, anonymity respected. They log back in and verify that their opinion is still there. 

All this done first when they are logged out, then again when logged in! Including the case where the user 
crafts an opinion when logged in, signs out, creates another opinion, then submits this new one, checking 
to see if the two opinions are merged properly.

Finally, logged in prolific user likes comments and adds their own. 

Not tested: 
  - being the first one to save a opinion
  - drag and drop inclusions (limitation of casper / phantom, prob soon to be fixed)
  - point is definitely deleted (e.g. discovered by refreshing the page)
  - ability to follow a proposal
  - subsumed opinion
  - commenting on your own new point
  - character count enforcement
  - point validation
  - points in margin when opened should have include button
  - points on decision board should have remove button

###

credentials = 
  email : 'testtestypuffinpie@tester.dev'
  username : 'testtestypuffinpie'
  password : '23423423425235345345'


current_user = null

opinion = 
  proposal_id: 'wash_i_517'
  stance : 1  
  points : 
    1: 
      is_pro : true
      anonymous : false
      nutshell : 'A highly intelligent point in favor'
      details : ''
    2: 
      is_pro : false
      anonymous : false
      nutshell : 'This would marginally increase inequity in the wild.'
      details : 'I have lots to say about this given my extensive knowledge. I have lots to say about this given my extensive knowledge. I have lots to say about this given my extensive knowledge. I have lots to say about this given my extensive knowledge. I have lots to say about this given my extensive knowledge.'
    3:
      is_pro : true
      anonymous : true
      nutshell : 'Secretly I am in favor of this for the simple fact that it will benefit me and me alone'
      details : ''
  included_points : [3472, 3492, 3539]

testCraftingOpinion = (test, opinion, state_suffix) ->

  ## Write some points

  casper.then ->
    casper.HTMLStep 'write points' + state_suffix
    _.each _.values(opinion.points), (point) ->
      points_col = if point.is_pro then '.pros_on_decision_board' else '.cons_on_decision_board'

      casper.then ->
        test.assertExists "#{points_col} [action='write-point']", 'Ability to write point' + state_suffix
        casper.click("#{points_col} [action='write-point']")

      casper.waitUntilVisible "#{points_col} .newpoint_form", ->
        @click "#{points_col} .newpoint_nutshell"
        @sendKeys "#{points_col} .newpoint_nutshell", point.nutshell

        @click "#{points_col} .newpoint_description"
        @sendKeys "#{points_col} .newpoint_description", point.details

        if point.anonymous
          @click '.newpoint-anonymous'

        casper.HTMLCapture '.four_columns_of_points', 
          caption : "Writing a point"

        casper.click "#{points_col} [action='submit-point']"

      casper.wait 3000, ->
        casper.HTMLCapture '.four_columns_of_points', 
          caption : "Point has saved"

        # test.assertSelectorHasText "#{points_col} .point_nutshell", point.nutshell, 'Point has been saved'

  # include some points
  casper.then ->
    use_drag_and_drop = false #drag and drop is not yet working
    casper.HTMLStep 'including some points' + state_suffix  
    _.each opinion.included_points, (point_id) ->
      casper.then ->
        draggable = "[role='point'][data-id='#{point_id}']"
        target = ".add_point_drop_target"

        # expand points if draggable isn't currently visible
        if !casper.exists draggable
          casper.then ->
            for points_col in ['.pros_by_community', '.cons_by_community']
              casper.click "#{points_col} [action='expand-toggle']"
              if casper.exists draggable
                break

        casper.then ->
          if use_drag_and_drop
            casper.dragAndDrop draggable, target
          else
            # include by opening point
            casper.click draggable
            casper.waitUntilVisible draggable + '.open_point', ->
              casper.thenClick draggable + '.open_point' + ' [action="point-include"]', ->

        casper.wait 1000, ->   #waitUntilVisible ".opinion_region #{draggable}", ->
          # test.assertVisible ".opinion_region #{draggable}", 'point has been included'
          if casper.exists '.points_are_expanded'
            #unexpand points if they were opened  
            casper.click ".points_are_expanded [action='expand-toggle']"

    casper.then ->
      casper.HTMLCapture '.four_columns_of_points', 
        caption : "After including some points"

  # move the slider
  # drag slider label won't work here, need to just click on slider base for now
  casper.then ->
    casper.HTMLStep 'Moving slider' + state_suffix  

    @evaluate ->
      target = '.noUi-base'
      event = document.createEvent("HTMLEvents")
      event.initEvent("mousedown", true, true)
      event.eventName = "mousedown"
      event.clientX = $(target).offset().left
      event.clientY = $(target).offset().top + 3
      $(target)[0].dispatchEvent(event)

    casper.wait 1000, ->
      casper.HTMLCapture '.four_columns_of_points', 
        caption : "Slider way to left"

  casper.then ->
    test.assertOpinionRepresented opinion, state_suffix

casper.test.assertOpinionRepresented = (opinion, state_suffix) ->
  casper.HTMLStep 'Verifying opinion is represented' + state_suffix  

  _.each _.values(opinion.points), (point) =>
    points_col = if point.is_pro then '.pros_on_decision_board' else '.cons_on_decision_board'
    @assertSelectorHasText "#{points_col} .point_nutshell", point.nutshell, 'Point has been saved'

  _.each opinion.included_points, (point_id) =>
    @assertVisible ".opinion_region [role='point'][data-id='#{point_id}']", 'point has been included'

  slider_base_pos = casper.getElementBounds '.noUi-base'
  slider_handle_pos = casper.getElementBounds '.noUi-handle'

  if opinion.stance == 1
    @assert slider_handle_pos.left < slider_base_pos.left && slider_handle_pos.left + slider_handle_pos.width > slider_base_pos.left, 'Slider has been moved way to the left'
  else if opinion.stance == 0
    @assert slider_handle_pos.left < slider_base_pos.left + slider_base_pos.width / 2 && slider_handle_pos.left + slider_handle_pos.width > slider_base_pos.left + slider_base_pos.width / 2, 'Slider is set to neutrality'

    throw 'implement test for neutrality'
  else
    throw 'Doesnt handle different slider pos yet...'


casper.test.begin 'Prolific contributor can craft their opinion', 110, (test) ->
  casper.executeLoggedInAndLoggedOut "http://localhost:8787/#{opinion.proposal_id}", (is_logged_in) ->

    opinion = 
      proposal_id: 'wash_i_517'
      stance : 1  
      points : 
        1: 
          is_pro : true
          anonymous : false
          nutshell : 'A highly intelligent point in favor'
          details : ''
        2: 
          is_pro : false
          anonymous : false
          nutshell : 'This would marginally increase inequity in the wild.'
          details : 'I have lots to say about this given my extensive knowledge. I have lots to say about this given my extensive knowledge. I have lots to say about this given my extensive knowledge. I have lots to say about this given my extensive knowledge. I have lots to say about this given my extensive knowledge.'
        3:
          is_pro : true
          anonymous : true
          nutshell : 'Secretly I am in favor of this for the simple fact that it will benefit me and me alone'
          details : ''
      included_points : [3472, 3492, 3539]



    state_suffix = if is_logged_in then ' when logged in' else ' when logged out'

    test.assertInCraftingState state_suffix

    # # write a point, open it, edit it, then delete it
    casper.then -> 
      casper.HTMLStep 'write a point, edit it, then delete it' + state_suffix

      @click(".cons_on_decision_board [action='write-point']")
      casper.waitUntilVisible ".cons_on_decision_board .newpoint_form", ->

        @sendKeys ".cons_on_decision_board .newpoint_nutshell", 'test test'
        @sendKeys ".cons_on_decision_board .newpoint_description", 'test details yo'
        @click ".cons_on_decision_board [action='submit-point']"

        casper.wait 1000, ->
          point_id = @getElementAttribute ".cons_on_decision_board .point:last-of-type", 'data-id'
          @click "[role='point'][data-id='#{point_id}']"

          @waitUntilVisible ".cons_on_decision_board .open_point", ->
            @then ->
              @click '.point_nutshell.editable'
              @waitUntilVisible '.editable-input textarea', ->
                @sendKeys '.editable-input textarea', ' edited'
                @click '.editable-buttons button[type="submit"]'
                @wait 200, ->
                  test.assertSelectorHasText '.point_nutshell.editable', 'test test edited', 'point nutshell can be edited'

            @then ->
              @click '.point_description.editable'
              @waitUntilVisible '.editable-input textarea', ->
                @sendKeys '.editable-input textarea', ' edited'
                @click '.editable-buttons button[type="submit"]'
                @wait 200, ->
                  test.assertSelectorHasText '.point_description.editable', 'test details yo edited', 'point description can be edited'

          @thenClick '.close_open_point', ->
            @waitWhileVisible '.open_point', ->
              @click "[role='point'][data-id='#{point_id}'] [action='point_remove']"
              @click ".cons_by_community [action='expand-toggle']"
              @wait 1000, ->
                test.assertDoesntExist "[role='point'][data-id='#{point_id}']", 'Point has been deleted'

    # include a point and remove it
    casper.then ->
      casper.HTMLStep 'include a point and then remove it' + state_suffix
      point_id = @getElementAttribute ".cons_by_community .point:last-of-type", 'data-id'
      @click "[role='point'][data-id='#{point_id}']"

      casper.waitUntilVisible '.open_point', ->
        casper.click '.open_point' + ' [action="point-include"]'

      casper.waitUntilVisible ".cons_on_decision_board [role='point'][data-id='#{point_id}']", ->
        test.assertVisible ".cons_on_decision_board [role='point'][data-id='#{point_id}']", 'Point was included' + state_suffix
        @click ".cons_on_decision_board [role='point'][data-id='#{point_id}'] [action='point-remove']"
        @click ".cons_by_community [action='expand-toggle']"
        casper.waitUntilVisible ".cons_by_community [role='point'][data-id='#{point_id}']", ->
          test.assertVisible ".cons_by_community [role='point'][data-id='#{point_id}']", 'Point was un-included' + state_suffix


    casper.then ->
      testCraftingOpinion test, opinion, state_suffix

    # go to homepage, then back to crafting, and see if opinion is still there
    casper.thenClick '[action="go-home"]', ->
      casper.HTMLStep 'Going to homepage then back to crafting to verify opinion still there' + state_suffix  
      casper.waitUntilVisible "[data-id='#{opinion.proposal_id}'] [action='craft-opinion']", ->
        casper.click "[data-id='#{opinion.proposal_id}'] [action='craft-opinion']"
        casper.waitUntilStateTransitioned 'crafting', ->
          test.assertOpinionRepresented opinion, state_suffix

    # go to results then back to crafting, and see if opinion is still there
    casper.thenClick '[action="view-results"]', ->
      casper.HTMLStep 'Going to results then back to crafting to verify opinion still there' + state_suffix  
      casper.waitUntilVisible "[data-id='#{opinion.proposal_id}'] [action='craft-opinion']", ->
        casper.click "[data-id='#{opinion.proposal_id}'] [action='craft-opinion']"
        casper.waitUntilStateTransitioned 'crafting', ->
          test.assertOpinionRepresented opinion, state_suffix

    # save opinion (with account creation if necessary)    
    casper.thenClick '[action="submit-opinion"]', ->
      casper.HTMLStep 'Saving opinion' + state_suffix  

      if !is_logged_in
        casper.waitUntilVisible '#user_email', -> 
          casper.mouse.click 'input#user_email'
          casper.sendKeys 'input#user_email', credentials.email
          casper.mouse.click 'input#password_none'
          casper.mouse.click '[action="create-account"]'
          casper.waitUntilVisible 'input#user_name', ->
            casper.sendKeys 'input#user_name', credentials.username
            casper.sendKeys 'input#user_password', credentials.password
            casper.mouse.click 'input#pledge1'
            casper.mouse.click 'input#pledge2'
            casper.mouse.click '[action="paperwork_complete"]'
        casper.waitUntilVisible '.user-options-display', -> test.assertLoggedIn()

      casper.waitUntilStateTransitioned 'results', ->
        casper.HTMLStep 'Verifying that opinion saved properly in histogram' + state_suffix  

        test.assert true, 'Made it to the results page after submitting opinion' 

        current_user = casper.getLoggedInUserid()
        if opinion.stance == 1
          test.assertVisible "[segment='0'] .avatar[data-id='#{current_user}']", 'User opinion reflected in correct place in histogram'
        else 
          throw 'not handling non-strong support stance at this time...'

        casper.HTMLCapture '[role="proposal"]', 
          caption : "User opinion in histogram"

      #refresh page to confirm still in histogram
      casper.reload ->
        casper.HTMLStep 'Refresh page to confirm still in histogram' + state_suffix  
        casper.waitUntilStateTransitioned 'results', ->
          current_user = casper.getLoggedInUserid()
          if opinion.stance == 1
            test.assertVisible "[segment='0'] .avatar[data-id='#{current_user}']", 'User opinion reflected in correct place in histogram'

      #update opinion to something else
      casper.then ->
        current_user = current_user = casper.getLoggedInUserid()

        casper.HTMLStep 'Update slider value' + state_suffix  
        casper.thenClick '[action="craft-opinion"]', ->
          casper.waitUntilStateTransitioned 'crafting', ->
            test.assertOpinionRepresented opinion, state_suffix

            # change to neutral stance
            opinion.stance = 0  
            @evaluate ->
              target = '.noUi-base'
              event = document.createEvent("HTMLEvents")
              event.initEvent("mousedown", true, true)
              event.eventName = "mousedown"
              event.clientX = $(target).offset().left + $(target).width()/2
              event.clientY = $(target).offset().top + 3
              $(target)[0].dispatchEvent(event)

            casper.wait 1000, ->
              casper.HTMLCapture '[role="proposal"]', 
                caption : "Slider set to neutral"

            casper.thenClick '[action="submit-opinion"]', ->
              casper.waitUntilStateTransitioned 'results', ->
                if opinion.stance == 0
                  test.assertVisible "[segment='3'] .avatar[data-id='#{current_user}']", 'User opinion reflected in correct place in histogram'
                else 
                  throw 'not handling non-strong support stance at this time...'

                casper.HTMLCapture '[role="proposal"]', 
                  caption : "User now in neutral bar"


    #logout
    casper.then ->
      casper.HTMLStep 'Logout and check to see if opinion is cleared and contributed points are properly respected' + state_suffix  

      actions.logout()
      casper.thenClick '[action="craft-opinion"]', ->
        casper.waitUntilStateTransitioned 'crafting', ->
    
          # check that contributed points are present; check that point anonymity is preserved
          _.each _.values(opinion.points), (point) =>
            points_col = if point.is_pro then '.pros_by_community' else '.cons_by_community'

            casper.click "#{points_col} [action='expand-toggle']"
            test.assertSelectorHasText "#{points_col} .point_nutshell", point.nutshell, 'Contributed point is now shared with community'
            if point.anonymous
              test.assertExists "[includers*='#{current_user}'] .avatar_anonymous", 'Point anonymity respected'
            casper.click ".points_are_expanded [action='expand-toggle']"

          # check opinion has been cleared
          test.assertElementCount '.opinion_region .point', 0, 'There aren\'t any points on the decision board'
          slider_base_pos = casper.getElementBounds '.noUi-base'
          slider_handle_pos = casper.getElementBounds '.noUi-handle'

          test.assert slider_handle_pos.left < slider_base_pos.left + slider_base_pos.width / 2 && slider_handle_pos.left + slider_handle_pos.width > slider_base_pos.left + slider_base_pos.width / 2, 'Slider is set to neutrality'

      # login and verify opinion still there
      if !is_logged_in
        casper.HTMLStep 'Login and verify opinion still there' + state_suffix  

        actions.login credentials.email, credentials.password
        casper.waitUntilVisible '.user-options-display', ->
          test.assertOpinionRepresented opinion, state_suffix

        # subsumed opinion

  casper.run ->
    test.done() 

point_to_open = 3466
casper.test.begin 'Prolific contributor can comment on points', 11, (test) ->
  casper.executeLoggedInAndLoggedOut "http://localhost:8787/#{opinion.proposal_id}/points/#{point_to_open}", (is_logged_in) ->

    casper.waitUntilVisible ".new_comment_body textarea", ->

      if is_logged_in
        current_user = casper.getLoggedInUserid()

        casper.then ->
          casper.HTMLStep 'Thank fact checker'

          test.assertExists ".claim_comment [action='thank-commenter']", 'Opportunity to thank a fact-checker'
          casper.click ".claim_comment [action='thank-commenter']"

          casper.waitForSelector '.claim_comment [action="unthank-commenter"]', ->

            test.assert true, 'Can thank fact-checker'

            casper.HTMLCapture '.open_point', 
              caption : "fact-checker thanked"

            test.assertExists ".claim_comment [action='unthank-commenter']", 'Opportunity to unthank a fact-checker'
            casper.click ".claim_comment [action='unthank-commenter']"
            casper.waitForSelector '.claim_comment [action="thank-commenter"]', ->
              test.assert true, 'Can unthank fact-checker'

        casper.then ->
          casper.HTMLStep 'Thank commenter'

          casper.click ".plain_comment [action='thank-commenter']"
          test.assertExists ".plain_comment [action='thank-commenter']", 'Can thank a commenter'          
          casper.waitUntilVisible '.plain_comment [action="unthank-commenter"]', ->
            test.assert true, 'Can thank commenter'

            casper.HTMLCapture '.open_point', 
              caption : "fact-checker thanked"

            test.assertExists ".plain_comment [action='unthank-commenter']", 'Opportunity to unthank a commenter'
            casper.click ".plain_comment [action='unthank-commenter']"
            casper.waitForSelector '.plain_comment [action="thank-commenter"]', ->
              test.assert true, 'Can unthank commenter'


        #comment the point
        casper.then ->
          casper.HTMLStep 'Comment on a point'

          casper.click ".new_comment_body textarea"

          @sendKeys ".new_comment_body textarea", "This is my awesome point"
          @click "[action='submit-comment']"

          casper.waitUntilVisible ".comment .avatar[data-id='#{current_user}']", ->
            test.assert true, 'Comment has been added'

            casper.HTMLCapture '.open_point', 
              caption : "Comment added"



      else
        # assert that commenting is disabled when not logged in
        test.assertDoesntExist "[action='submit-comment']", 'cant comment when not logged in'
        # assert that can't thank
        test.assertDoesntExist "[action='thank-commenter']", 'cant thank other comments when not logged in'

        casper.HTMLCapture '.open_point', 
          caption : "Open point when not logged"

  casper.run ->
    test.done() 