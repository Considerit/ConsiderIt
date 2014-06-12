require('../library/casper')
require('../library/asserts')
actions = require('../library/actions')
_ = require('../../node_modules/underscore')

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
  - when logging in to comment on a point, already entered comment should be saved and user should stay on the point page
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
    included_points : [ [3472, true], [3492, false], [3539, false]]

testCraftingOpinion = (test, opinion, state_suffix) ->

  ## Write some points

  casper.then ->
    casper.logStep 'write points' + state_suffix
    _.each _.values(opinion.points), (point) ->
      points_col = if point.is_pro then '.pros_on_decision_board' else '.cons_on_decision_board'

      casper.then ->
        test.assertExists "#{points_col} [action='write-point']", 'Ability to write point' + state_suffix
      
      casper.thenClick("#{points_col} [action='write-point']")

      casper.waitUntilVisible "#{points_col} .newpoint_form", null, -> test.fail 'New point form never shows up'

      casper.then ->
        @click "#{points_col} .newpoint_nutshell"
        @sendKeys "#{points_col} .newpoint_nutshell", point.nutshell

        @click "#{points_col} .newpoint_description"
        @sendKeys "#{points_col} .newpoint_description", point.details

        if point.anonymous
          @click '.newpoint-anonymous'

        casper.HTMLCapture '.reasons_region', 
          caption : "Writing a point"


      casper.thenClick "#{points_col} [action='submit-point']"

      casper.wait 3000, ->
        casper.HTMLCapture '.reasons_region', 
          caption : "Point has saved"

        # test.assertSelectorHasText "#{points_col} .point_nutshell", point.nutshell, 'Point has been saved'

  # include some points
  casper.then ->
    use_drag_and_drop = false #drag and drop is not yet working in casper
    casper.logStep 'including some points' + state_suffix  
    _.each opinion.included_points, (point) ->
      [point_id, is_pro] = point
      casper.then ->
        draggable = "[data-role='point'][data-id='#{point_id}']"
        target = ".add_point_drop_target"

        # expand points if draggable isn't currently visible
        if !casper.exists draggable
          points_col = if is_pro then '.pros_by_community' else '.cons_by_community'
          casper.thenClick "#{points_col} [action='expand-toggle']"

        casper.wait 50, ->
          if use_drag_and_drop
            casper.dragAndDrop draggable, target
          else
            # include by opening point
            casper.thenClick draggable + ' .point_content'
            casper.waitUntilVisible draggable + '.open_point', null, -> test.fail 'Point is never actually opened'
            casper.thenClick draggable + '.open_point' + ' [action="point-include"]'

        casper.wait 1000, ->   #waitUntilVisible ".opinion_region #{draggable}", ->
          # test.assertVisible ".opinion_region #{draggable}", 'point has been included'
          if casper.exists '.points_are_expanded'
            #unexpand points if they were opened  
            casper.click ".points_are_expanded [action='expand-toggle']"

    casper.then ->
      casper.HTMLCapture '.reasons_region', 
        caption : "After including some points"

  # move the slider
  # drag slider label won't work here, need to just click on slider base for now
  casper.then ->
    casper.logStep 'Moving slider' + state_suffix  

    @evaluate ->
      target = '.noUi-base'
      event = document.createEvent("HTMLEvents")
      event.initEvent("mousedown", true, true)
      event.eventName = "mousedown"
      event.clientX = $(target).offset().left
      event.clientY = $(target).offset().top + 3
      $(target)[0].dispatchEvent(event)

    casper.wait 1000, ->
      casper.HTMLCapture '.reasons_region', 
        caption : "Slider way to left"

  casper.then ->
    test.assertOpinionRepresented opinion, state_suffix

casper.test.assertOpinionRepresented = (opinion, state_suffix) ->
  casper.logStep 'Verifying opinion is represented' + state_suffix  

  _.each _.values(opinion.points), (point) =>
    points_col = if point.is_pro then '.pros_on_decision_board' else '.cons_on_decision_board'
    @assertSelectorHasText "#{points_col} .point_nutshell", point.nutshell, 'Point has been saved'

  _.each opinion.included_points, (point) =>
    [point_id, is_pro] = point
    @assertVisible ".opinion_region [data-role='point'][data-id='#{point_id}']", 'point has been included'

  slider_base_pos = casper.getElementBounds '.noUi-base'
  slider_handle_pos = casper.getElementBounds '.noUi-handle'

  if opinion.stance == 1
    @assert slider_handle_pos.left < slider_base_pos.left && slider_handle_pos.left + slider_handle_pos.width > slider_base_pos.left, 'Slider has been moved way to the left'
  else if opinion.stance == 0
    @assert slider_handle_pos.left < slider_base_pos.left + slider_base_pos.width / 2 && slider_handle_pos.left + slider_handle_pos.width > slider_base_pos.left + slider_base_pos.width / 2, 'Slider is set to neutrality'
  else
    throw 'Doesnt handle different slider pos yet...'


casper.test.begin 'Prolific contributor can craft their opinion', 120, (test) ->
  actions.executeLoggedInAndLoggedOut "http://localhost:8787/#{opinion.proposal_id}", (is_logged_in) ->

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
      included_points : [ [3472, true], [3492, false], [3539, false]]


    state_suffix = if is_logged_in then ' when logged in' else ' when logged out'

    test.assertInCraftingState state_suffix

    # include a point and remove it
    casper.then ->
      @logStep 'include a point and then remove it' + state_suffix
      point_id = @getElementAttribute ".cons_by_community .point:last-of-type", 'data-id'
      @thenClick "[data-role='point'][data-id='#{point_id}'] .point_content"

      @waitUntilVisible '.open_point', null, -> test.fail 'point never opens'
      @thenClick '.open_point' + ' [action="point-include"]'

      @waitUntilVisible ".cons_on_decision_board [data-role='point'][data-id='#{point_id}']", ->
        test.assertVisible ".cons_on_decision_board [data-role='point'][data-id='#{point_id}']", 'Point was included' + state_suffix
      , -> test.fail 'point is never included'

      @thenClick ".cons_by_community [action='expand-toggle']"
      @thenClick ".cons_on_decision_board [data-role='point'][data-id='#{point_id}'] [action='point-remove']"
      @waitUntilVisible ".cons_by_community [data-role='point'][data-id='#{point_id}']", ->
        test.assertVisible ".cons_by_community [data-role='point'][data-id='#{point_id}']", 'Point was un-included' + state_suffix
      , -> test.fail 'point is never unincluded'


    # # write a point, open it, edit it, then delete it
    casper.then -> 
      @logStep 'write a point, edit it, then delete it' + state_suffix

      @waitUntilVisible ".cons_on_decision_board [action='write-point']", null, -> test.fail 'ability to write new point does not appear'
      @thenClick ".cons_on_decision_board [action='write-point']"

      @waitUntilVisible ".cons_on_decision_board .newpoint_form [action='submit-point']", ->
        @sendKeys ".cons_on_decision_board .newpoint_nutshell", 'test test'
        @sendKeys ".cons_on_decision_board .newpoint_description", 'test details yo'
      , -> test.fail 'new point form does not appear'

      @thenClick ".cons_on_decision_board [action='submit-point']"

      point_id = null # so that point_id is in wider scope
      @waitUntilVisible '.cons_on_decision_board .point', ->
        point_id = @getElementAttribute ".cons_on_decision_board .point:last-of-type", 'data-id'
      , -> test.fail 'Point was never added'

      @then -> 
       
        @thenClick "[data-role='point'][data-id='#{point_id}'] .point_content"

        @waitUntilVisible ".cons_on_decision_board .open_point", null, -> test.fail 'Point did not open'

        @wait 300, ->
          test.assertExists '.point_nutshell.editable', 'Can edit nutshell'

        @thenClick '.point_nutshell.editable'
        @waitUntilVisible '.editable-input textarea', ->
          @sendKeys '.editable-input textarea', ' edited'
          @thenClick '.editable-buttons button[type="submit"]'
          @waitWhileVisible 'editable-container'
          @wait 200, ->
            test.assertSelectorHasText '.point_nutshell.editable', 'test test edited', 'point nutshell can be edited'
        , -> test.fail 'point nutshell editable never appears'

        @thenClick '.point_description.editable'
        @waitUntilVisible '.editable-input textarea', ->
          @sendKeys '.editable-input textarea', ' edited'
          @click '.editable-buttons button[type="submit"]'
          @waitWhileVisible 'editable-container'
          @wait 200, ->
            test.assertSelectorHasText '.point_description.editable', 'test details yo edited', 'point description can be edited'
        , -> test.fail 'point details editable never appears'

        @thenClick '.close_open_point'
        @waitWhileVisible '.open_point', ->
          @click "[data-role='point'][data-id='#{point_id}'] [action='point-remove']"
          @click ".cons_by_community [action='expand-toggle']"
          @wait 1000, ->
            test.assertDoesntExist "[data-role='point'][data-id='#{point_id}']", 'Point has been deleted'
        , -> test.fail 'open point never closes'



    casper.then ->
      testCraftingOpinion test, opinion, state_suffix

    # go to homepage, then back to crafting, and see if opinion is still there
    casper.thenClick '[action="go-home"]', ->
      @logStep 'Going to homepage then back to crafting to verify opinion still there' + state_suffix  
      @waitUntilVisible "[data-id='#{opinion.proposal_id}'] [action='craft-opinion']", null, -> test.fail 'proposal is never in summary view'
      @thenClick "[data-id='#{opinion.proposal_id}'] [action='craft-opinion']"
      @waitUntilStateTransitioned 'crafting', null, -> test.fail 'Crafting state is never entered'
      @wait 1000, ->
        test.assertOpinionRepresented opinion, state_suffix
      

    # go to results then back to crafting, and see if opinion is still there
    casper.thenClick '[action="view-results"]', ->
      @logStep 'Going to results then back to crafting to verify opinion still there' + state_suffix  
      @waitUntilVisible "[data-id='#{opinion.proposal_id}'] [action='craft-opinion']", null, -> test.fail 'proposal is never in summary view'
      @thenClick "[data-id='#{opinion.proposal_id}'] [action='craft-opinion']"
      @waitUntilStateTransitioned 'crafting', ->
        test.assertOpinionRepresented opinion, state_suffix
      , -> test.fail 'Crafting state is never entered'

    # save opinion (with account creation if necessary)    
    casper.thenClick '[action="submit-opinion"]', ->
      @logStep 'Saving opinion' + state_suffix  

      if !is_logged_in
        @waitUntilVisible '#user_email', -> 
          @mouse.click 'input#user_email'
          @sendKeys 'input#user_email', credentials.email
          @mouse.click 'input#password_none'
          @mouse.click '[action="create-account"]'
          @waitUntilVisible 'input#user_name', ->
            @sendKeys 'input#user_name', credentials.username
            @sendKeys 'input#user_password', credentials.password
            @mouse.click 'input#pledge1'
            @mouse.click 'input#pledge2'
            @mouse.click '[action="paperwork_complete"]'
        , -> test.fail 'login form never appears'
        @waitUntilVisible '.user-options-display', -> 
          test.assertLoggedIn()
        , -> test.fail 'never logged in'

      @waitUntilStateTransitioned 'results', ->
        @logStep 'Verifying that opinion saved properly in histogram' + state_suffix  

        test.pass 'Made it to the results page after submitting opinion' 

        current_user = @getLoggedInUserid()
        if opinion.stance == 1
          test.assertVisible "[segment='0'] .avatar[data-id='#{current_user}']", 'User opinion reflected in correct place in histogram'
        else 
          throw 'not handling non-strong support stance at this time...'

        @HTMLCapture '[data-role="proposal"]', 
          caption : "User opinion in histogram"
      , -> test.fail 'Never entered results state'

      #refresh page to confirm still in histogram
      @reload ->
        @logStep 'Refresh page to confirm still in histogram' + state_suffix  
        @waitUntilStateTransitioned 'results', ->
          current_user = @getLoggedInUserid()
          if opinion.stance == 1
            test.assertVisible "[segment='0'] .avatar[data-id='#{current_user}']", 'User opinion reflected in correct place in histogram'
        , -> test.fail 'Never entered results state'

      #update opinion to something else
      @then ->
        current_user = current_user = @getLoggedInUserid()

        @logStep 'Update slider value' + state_suffix  
        @thenClick '[action="craft-opinion"]'
        @waitUntilStateTransitioned 'crafting', null, -> test.fail 'Never entered crafting state'

        @then ->
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


          @wait 1000, ->
            @HTMLCapture '[data-role="proposal"]', 
              caption : "Slider set to neutral"

          @thenClick '[action="submit-opinion"]'
          @waitUntilStateTransitioned 'results', ->
            if opinion.stance == 0
              test.assertVisible "[segment='3'] .avatar[data-id='#{current_user}']", 'User opinion reflected in correct place in histogram'
            else 
              throw 'not handling non-strong support stance at this time...'

            @HTMLCapture '[data-role="proposal"]', 
              caption : "User now in neutral bar"
          , -> test.fail 'Never entered results state'

    #logout
    casper.then ->
      @logStep 'Logout and check to see if opinion is cleared and contributed points are properly respected' + state_suffix  

      actions.logout()

      @thenClick '[action="craft-opinion"]'
      @waitUntilStateTransitioned 'crafting', null, -> test.fail 'Never entered crafting state'
  
      @then -> 
        # check that contributed points are present; check that point anonymity is preserved
        _.each _.values(opinion.points), (point) =>
          points_col = if point.is_pro then '.pros_by_community' else '.cons_by_community'

          @click "#{points_col} [action='expand-toggle']"
          test.assertSelectorHasText "#{points_col} .point_nutshell", point.nutshell, 'Contributed point is now shared with community'
          if point.anonymous
            test.assertExists "[includers*='#{current_user}'] .avatar_anonymous", 'Point anonymity respected'
          @click ".points_are_expanded [action='expand-toggle']"

        # check opinion has been cleared
        test.assertElementCount '.opinion_region .point', 0, 'There aren\'t any points on the decision board'
        slider_base_pos = @getElementBounds '.noUi-base'
        slider_handle_pos = @getElementBounds '.noUi-handle'

        test.assert slider_handle_pos.left < slider_base_pos.left + slider_base_pos.width / 2 && slider_handle_pos.left + slider_handle_pos.width > slider_base_pos.left + slider_base_pos.width / 2, 'Slider is set to neutrality'

      @then ->
        # login and verify opinion still there
        if !is_logged_in
          @logStep 'Login and verify opinion still there' + state_suffix  

          actions.login credentials.email, credentials.password
          @wait 1000, ->
            test.assertOpinionRepresented opinion, state_suffix

          # subsumed opinion


  casper.run ->
    test.done() 

point_to_open = 3466
casper.test.begin 'Prolific contributor can comment on points', 11, (test) ->
  actions.executeLoggedInAndLoggedOut "http://localhost:8787/#{opinion.proposal_id}/points/#{point_to_open}", (is_logged_in) ->

    casper.waitUntilVisible ".new_comment_body textarea", null, -> test.fail 'ability to write comment does not show up'

    casper.then ->

      if is_logged_in
        current_user = @getLoggedInUserid()

        @then -> 
          @logStep 'Thank commenter'
          test.assertExists "#comment_721 [action='thank-commenter']", 'Opportunity to thank a commenter'          

        @thenClick "#comment_721 [action='thank-commenter']"

        @waitUntilVisible '#comment_721 [action="unthank-commenter"]', ->
          test.pass 'Can thank commenter'
          @HTMLCapture '.open_point', 
            caption : "commenter thanked"
          test.assertExists "#comment_721 [action='unthank-commenter']", 'Opportunity to unthank a commenter'
        , -> test.fail 'No opportunity to unthank commenter'

        @thenClick "#comment_721 [action='unthank-commenter']" #this submits two clicks!!!!
        @waitForSelector '#comment_721 [action="thank-commenter"]', ->
          test.pass 'Can unthank commenter'
        , -> 
          @HTMLCapture 'body', 
            caption : "WHYYYYY"

          casper.echo "IS PRESENT? #{casper.exists('#comment_721 [action=\'unthank-commenter\']')}"
          test.fail 'Cannot unthank commenter'


        @then -> 
          @logStep 'Thank fact checker'
          test.assertExists "#claim_comment_125 [action='thank-commenter']", 'Opportunity to thank a fact checker'

        @thenClick "#claim_comment_125 [action='thank-commenter']"
        @waitForSelector '#claim_comment_125 [action="unthank-commenter"]', ->
          test.pass 'Can thank fact checker'
          @HTMLCapture '.open_point', 
            caption : "fact-checker thanked"
          test.assertExists "#claim_comment_125 [action='unthank-commenter']", 'Opportunity to unthank a fact checker'
        , -> test.fail 'No opportunity to unthank fact checker'

        @thenClick "#claim_comment_125 [action='unthank-commenter']"
        @waitForSelector '#claim_comment_125 [action="thank-commenter"]', ->
          test.pass 'Can unthank fact checker'
        , -> 
          @HTMLCapture '.open_point', 
            caption : "WHYYYYY"

          casper.echo "IS PRESENT? #{casper.exists('#claim_comment_125 [action=\'unthank-commenter\']')}"
          test.fail 'Cannot unthank fact checker'


        #comment the point
        @thenClick ".new_comment_body textarea", ->
          @logStep 'Comment on a point'
          @sendKeys ".new_comment_body textarea", "This is my awesome point"

        @thenClick "[action='submit-comment']"
        @waitUntilVisible ".comment .avatar[data-id='#{current_user}']", ->
          test.pass 'Comment has been added'
          @HTMLCapture '.open_point', 
            caption : "Comment added"
        , -> test.fail 'Comment is never submitted'

      else
        # assert that commenting is disabled when not logged in
        test.assertDoesntExist "[action='submit-comment']", 'cant comment when not logged in'
        # assert that can't thank
        test.assertDoesntExist "[action='thank-commenter']", 'cant thank other comments when not logged in'

        @HTMLCapture '.open_point', 
          caption : "Open point when not logged"

  casper.run ->
    test.done() 