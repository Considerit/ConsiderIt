require('../library/casper')
require('../library/asserts')
actions = require('../library/actions')

###
Tests actions by a lurker. Click around homepage and proposals.

Not yet tested here:
  - clicking inactive proposals first
  - proper sort order of the proposals given different sorts
  - whether clicking to load the same proposal tries to load data again from the server
  - differences between active and inactive proposals
  - whether you can expand points, sorted accurated, while having a histogram bar selected
  - whether thanking and commenting is enabled based on whether or not logged in
  - sorting expanded points
  - when navigating back to the user profile page from e.g. a user's point, does not check nav behavior of closing the point
  - lurking on an inactive proposal
  - lurking on a no-activity proposal
  - going to right page after opening and closing points and positions
###

test_open_point = (test, state_suffix = '') ->
  casper.logStep 'open a point' + state_suffix
  casper.thenClick '[data-role="point"] .point_content'
  casper.waitUntilVisible '.open_point', ->
    test.assertPointIsOpen()
    #TODO: if logged in, can thank and comment; if not, cannot thank or comment
    casper.HTMLCapture '.open_point', 
      caption : "Opened point" + state_suffix

  casper.thenClick '.close_open_point', ->
    test.assertDoesntExist '.open_point', 'point closes' + state_suffix

test_expanding_points = (test, state_suffix = '') ->
  casper.logStep 'expand points' + state_suffix
  casper.thenClick '[action="expand-toggle"]', ->
    test.assertExists '.points_are_expanded', 'points are expanded' + state_suffix
    casper.HTMLCapture '.reasons_region', 
      caption : "Expanded points"

    test.assertVisible '.sort_points', 'user can see the sort option' + state_suffix
    casper.mouse.move '.sort_points_label'

    test.assertVisible '.sort_points_menu', 'user can see the sort menu on hover' + state_suffix

    casper.HTMLCapture '.points_are_expanded', 
      caption : "Hovering over sort"

  casper.thenClick '.sort_points .sort_points_menu_option [action="persuasiveness"]', ->
    casper.HTMLCapture '.points_are_expanded', 
      caption : "after clicking persuasiveness sort" + state_suffix

  casper.thenClick '[action="expand-toggle"]', ->
    test.assertDoesntExist '.points_are_expanded', 'points are unexpanded' + state_suffix
    casper.HTMLCapture '.reasons_region', 
      caption : "after unexpanding" + state_suffix

test_histogram = (test, state, state_suffix) ->
  @logStep "#{state} histogram #{state_suffix}"

  test.assertElementCount '.histogram_bar .histogram_bar_users', 7, 'Has seven histogram bars'

  @then -> 
    if state == 'hover'
      @mouse.move '.histogram_bar[segment="0"]'     
    else
      @click '.histogram_bar[segment="0"]'  
      @mouse.move 'body'

  @waitUntilVisible '.histogram_bar[segment="0"].bar_is_selected', ->
    @wait 2000, ->
      test.assertSelectorHasText '.pros_by_community .points_heading_label', 'Pros', "Pros present in pros header when #{state}" + state_suffix

      # this instrumentation doesn't seem to trigger the bar selection for whatever reason...
      #test.assertSelectorHasText '.pros_by_community .points_heading_label', 'upport', "Supporter is present in pros header when #{state}" + state_suffix

      @HTMLCapture '[data-role="proposal"]', 
        caption : "#{state} histogram bar" + state_suffix
  , -> test.fail 'Bar is never selected'  

test_profile_action_summary = (test, user_id, action, callback) ->
  casper.then -> 
    casper.thenOpen "http://localhost:8787/dashboard/users/#{user_id}/profile"
    casper.wait 100
    casper.waitUntilVisible "[action='#{action}']", null, -> test.fail("[action='#{action}'] never became visible")
    casper.thenClick "[action='#{action}']"
    casper.waitUntilVisible '.dashboard-profile-activity-substance-wrap', null, -> test.fail("Never loaded #{action} area")
    casper.wait 200, ->
      @logStep "Access #{action} from profile"

      test.assertVisible '.dashboard-profile-activity-substance-wrap', "Has some #{action} listed"
      test.assertVisible '.dashboard-profile-activity-action a', "Has a link to #{action}"

      casper.then -> 
        entity_id = @evaluate -> return $(".dashboard-profile-activity-action:visible a:first").attr('data-id')
        @click(".dashboard-profile-activity-action a[data-id='#{entity_id}']")

        callback.call casper, entity_id

      casper.then ->
        @back()
        casper.waitUntilVisible "[action='#{action}']", ->
          test.assertInUserProfile()
        , -> test.fail('Could not navigate back to profile')





# used in these tests when a specific proposal is needed to be referenced
example_proposal = "wash_i_522"

casper.test.begin 'Lurker can poke around homepage', 26, (test) ->

  actions.executeLoggedInAndLoggedOut "http://localhost:8787/", (is_logged_in) ->
    state_suffix = if is_logged_in then ' when logged in' else ' when logged out'

    @waitUntilVisible '[data-role="proposal"]', ->
      @logStep "Homepage can be mucked about" + state_suffix

      @HTMLCapture 'body', 
        caption: 'Full homepage, different sizes' + state_suffix
        sizes: [ [1200, 900], [600, 500], [1024, 768] ]

      @HTMLCapture '[data-role="proposal"]', 
        caption: 'One of the proposals' + state_suffix

      @HTMLCapture '#active_proposals_region', 
        caption: 'Active proposals' + state_suffix

      test.assertOnHomepage()

    # loading more active proposals
    @thenClick('#active_proposals_region [action="load-proposals"]').waitUntilVisible '[action="proposals:goto_page"]', ->
      @logStep "load some more proposals" + state_suffix
      @HTMLCapture '#active_proposals_region', 
        caption: 'Active proposals' + state_suffix

      test.assertExists '[action="proposals:goto_page"]', 'pagination is shown after loading proposals' + state_suffix
      @HTMLCapture '.proposals-operations',
        caption: 'Proposals pagination after loading more' + state_suffix

    # check if can load more inactive proposals
    # @thenClick('#past_proposals_region [action="load-proposals"]').waitUntilVisible '#past_proposals_region [action="proposals:goto_page"]', ->
    @then ->
      @logStep "Access inactive proposals" + state_suffix
      test.assertExists '#past_proposals_region [action="proposals:goto_page"]', 'pagination for inactive proposals is shown after loading inactive proposals' + state_suffix

    # test accessing homepage from a different page
    @thenOpen("http://localhost:8787/#{example_proposal}").waitUntilVisible '[action="go-home"]', ->
      @logStep "Homepage can be accessed from different page" + state_suffix
      test.assertExists '[action="go-home"]', 'Opportunity to navigate to homepage' + state_suffix

    @thenClick '[action="go-home"]'
    @waitWhileSelector '[action="go-home"]', ->
      test.assertOnHomepage()


  casper.run ->
    test.done() 

casper.test.begin 'Lurker can poke around a proposal results page', 90, (test) ->

  actions.executeLoggedInAndLoggedOut "http://localhost:8787/", (is_logged_in) ->
    #TODO: loop, once going to active proposal, next to an inactive proposal
    #TODO: loop, proposal with activity and without activity

    state_suffix = if is_logged_in then ' when logged in' else ' when logged out'

    # make sure results page can be accessed from homepage
    @waitUntilVisible '[data-role="proposal"]', ->
      @logStep "Results page can be accessed from homepage" + state_suffix
      test.assertExists '[data-role="proposal"] .points_by_community[data-state="summary"]', 'Peer reasons exists in collapsed form' + state_suffix

    @thenClick '[data-role="proposal"]:first-of-type .points_by_community[data-state="summary"]:first-of-type'
    @waitUntilStateTransitioned 'results', ->
      @HTMLCapture 'body', 
        caption : 'The results page' + state_suffix

      test.assertInResultsState()

    # make sure results page can be accessed from crafting page
    @thenOpen("http://localhost:8787/#{example_proposal}").waitUntilVisible '[action="view-results"]', ->
      @logStep "Results page can be accessed from crafting page" + state_suffix
      test.assertInCraftingState state_suffix

    @thenClick '[action="view-results"]'
    @waitUntilStateTransitioned 'results', ->
      test.assertInResultsState()

    # make sure results page can be directly opened
    @thenOpen("http://localhost:8787/#{example_proposal}/results").waitUntilStateTransitioned 'results', ->
      @logStep "Results page can be directly opened" + state_suffix
      test.assertInResultsState()

    # hover over histogram
    @then -> test_histogram.call casper, test, 'hover', state_suffix

    # click on histogram
    @then -> test_histogram.call casper, test, 'click', state_suffix

    # hover over a point
    @then ->
      @logStep 'hover over a point' + state_suffix

      @mouse.move 'body'
      point_includers = @evaluate ->
        return _.uniq($('[data-role="point"]:first').attr("includers").split(',')).length

      total_avatars = @evaluate -> return $(".feelings_region .avatar:visible").length

      @mouse.move '[data-role="point"]'
      @wait 200, ->
        @HTMLCapture '[data-role="proposal"]', 
          caption : "Hovering over a point" + state_suffix

        includers_hidden = @evaluate -> 
          hidden = -> $(this).css('opacity') == '0' || $(this).css('visibility') == 'hidden'
          return $(".feelings_region .avatar:visible").filter(hidden).length

        test.assertEqual total_avatars - includers_hidden, point_includers, 'Only includers shown on point hover' + state_suffix

    # open a point
    @then -> test_open_point test, state_suffix

    # expand the points
    @then -> test_expanding_points test, state_suffix

  casper.run ->
    test.done() 


casper.test.begin 'Lurker can poke around the proposal crafting page', 72, (test) ->

  actions.executeLoggedInAndLoggedOut "http://localhost:8787/", (is_logged_in) ->
    state_suffix = if is_logged_in then ' when logged in' else ' when logged out'

    # navigate to crafting page from homepage
    @waitUntilVisible '[data-role="proposal"]', ->
      @logStep "Crafting page can be navigated to from homepage" + state_suffix

      test.assertExists '[data-role="proposal"] [action="craft-opinion"]', 'Opportunity to add one\'s opinion' + state_suffix
    @thenClick '[data-role="proposal"]:first-of-type [action="craft-opinion"]:first-of-type'
    @waitUntilStateTransitioned 'crafting', ->
      test.assertInCraftingState state_suffix

    # access crafting page from results page
    @thenOpen("http://localhost:8787/#{example_proposal}/results").waitUntilStateTransitioned 'results', ->

      @logStep "Crafting page can be accessed from results page" + state_suffix

      test.assertExists '[data-role="proposal"] [action="craft-opinion"]', 'Opportunity to add one\'s opinion' + state_suffix

    @thenClick '[data-role="proposal"] [action="craft-opinion"]:first-of-type'
    @waitUntilStateTransitioned 'crafting', ->
      test.assertInCraftingState state_suffix

    # open crafting page directly
    @thenOpen("http://localhost:8787/#{example_proposal}").waitUntilStateTransitioned 'crafting', ->
      @logStep "Crafting page can be directly opened" + state_suffix

      @HTMLCapture 'body', 
        caption: 'Full crafting page, different sizes' + state_suffix
        sizes: [ [1200, 900], [600, 500], [1024, 768] ]

      test.assertInCraftingState state_suffix

    # open a point
    @then -> test_open_point test, state_suffix

    # expand points
    @then -> test_expanding_points test, state_suffix

  casper.run ->
    test.done() 

example_user = 1701

casper.test.begin 'Lurker can poke around a user profile', 27, (test) ->
  casper.start "http://localhost:8787/#{example_proposal}"

  # can access a profile page from elsewhere
  casper.waitUntilVisible '[tooltip="user_profile"]', ->
    @logStep "Profile page can be accessed from other page"
    test.assertExists '[tooltip="user_profile"]', 'User profile link exists'
  casper.thenClick '.points_by_community [tooltip="user_profile"]:first-of-type'
  casper.waitUntilVisible '.dashboard-profile-influence-summary', ->
    test.assertInUserProfile()

  # can open a profile page directly
  casper.thenOpen("http://localhost:8787/dashboard/users/#{example_user}/profile")

  casper.waitUntilVisible '.dashboard-profile-influence-summary', ->
    @logStep "Profile page can be directly opened"

    @HTMLCapture 'body', 
      caption: 'User profile page, different sizes'
      sizes: [ [1200, 900], [600, 500], [1024, 768] ]

    test.assertInUserProfile()

  # testing the Points listed in someone's profile
  test_profile_action_summary test, example_user, 'points', (entity_id) ->
    @waitUntilVisible '.open_point', ->
      test.assertPointIsOpen()
    , -> test.fail 'Could not open a point'

  # testing the Opinions listed in someone's profile
  test_profile_action_summary test, example_user, 'opinions', (entity_id) ->
    @waitUntilVisible '.user_opinion', ->
      @HTMLCapture 'body', 
        caption: 'opinion page, accessed from profile'
      test.assertUserOpinionVisible()
    , -> test.fail 'Could not open an opinion'

  # testing the Proposals listed in someone's profile
  test_profile_action_summary test, 1, 'proposals', (entity_id) ->
    @waitUntilVisible '[data-state="results"]', ->
      test.assertInResultsState()
    , -> test.fail 'Could not open a proposal'

  # testing the Comments listed in someone's profile
  test_profile_action_summary test, example_user, 'comments', (entity_id) ->
    @waitUntilVisible '.open_point', ->
      test.assertCommentIsVisible entity_id
    , -> test.fail 'Could not open a comment'

  casper.run ->
    test.done() 



