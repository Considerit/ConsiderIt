###
Tests actions by a lurker. Click around homepage and proposals.

Execute these tests twice, once with a user that is logged in already, and once with anon.

Not yet tested here:
  - clicking inactive proposals first
  - proper sort order of the proposals given different sorts
  - whether clicking to load the same proposal tries to load data again from the server
  - differences between active and inactive proposals
  - whether you can browse points, sorted accurated, while having a histogram bar selected
  - whether thanking and commenting is enabled based on whether or not logged in
  - sorting points when browsing points
  - when navigating back to the user profile page from e.g. a user's point, does not check nav behavior of closing the point
###


# used in these tests when a specific proposal is needed to be referenced
example_proposal = "wash_i_522"

casper.test.begin 'Lurker can poke around homepage', 13, (test) ->

  #TODO: loop here, once with logged in user, once without
  casper.start "http://localhost:8787/", ->

    casper.then ->
      casper.wait 1000, ->
        @HTMLStep "Homepage can be mucked about"

        @HTMLCapture 'body', 
          caption: 'Full homepage, different sizes'
          sizes: [ [1200, 900], [600, 500], [1024, 768] ]

        @HTMLCapture '[data-role="proposal"]', 
          caption: 'One of the proposals'

        @HTMLCapture '#proposals-container', 
          caption: 'Active proposals'

        assert_homepage_loaded test

    casper.then ->
      @HTMLStep "load some more proposals"

      @click '#proposals-container [data-target="load-proposals"]'
      @wait 10000, ->
        @HTMLCapture '#proposals-container', 
          caption: 'Active proposals'

        test.assertExists '[data-target="proposallist:page"]', 'pagination is shown after loading proposals'
        @HTMLCapture '.proposals-operations',
          caption: 'Proposals pagination after loading more'

        @click '#proposals-container-completed [data-target="load-proposals"]'
        @wait 10000, ->
          test.assertExists '#proposals-container-completed [data-target="proposallist:page"]', 'pagination for inactive proposals is shown after loading inactive proposals'

    casper.then ->
      casper.open("http://localhost:8787/#{example_proposal}").wait 5000, ->
        @HTMLStep "Homepage can be accessed from different page"
        test.assertExists '[data-target="go-home"]', 'Opportunity to navigate to homepage'
        @click '[data-target="go-home"]'
        @wait 1000, ->
          assert_homepage_loaded test


  casper.run ->
    test.done() 



casper.test.begin 'Lurker can poke around a proposal results page', 35, (test) ->

  #TODO: loop here, once with logged in user, once without
  casper.start "http://localhost:8787/", ->

    #TODO: loop, once going to active proposal, next to an inactive proposal
    #TODO: loop, proposal with activity and without activity

    casper.then -> 
      @wait 1000, ->
        @HTMLStep 'Results page can be accessed from homepage'
        test.assertExists '[data-role="proposal"] .peer-reasons[data-state="points-collapsed"]', 'Peer reasons exists in collapsed form'
        @click '[data-role="proposal"]:first-of-type .peer-reasons[data-state="points-collapsed"]:first-of-type'
        @wait 5000, ->
          @HTMLCapture 'body', 
            caption : 'The results page'

          assert_in_results_state test

    casper.then ->

      casper.open("http://localhost:8787/#{example_proposal}").wait 5000, ->
        @HTMLStep "Results page can be accessed from crafting page"
        test.assertExists '[data-target="view-results"]', 'Opportunity to navigate to results page'
        @click '[data-target="view-results"]'
        @wait 1000, ->
          assert_in_results_state test

    casper.then ->
      casper.open("http://localhost:8787/#{example_proposal}/results").wait 5000, ->
        @HTMLStep "Results page can be directly opened"
        assert_in_results_state test


    execute_histogram_tests = (state) =>
      @HTMLStep "#{state} histogram"

      if state == 'hover'
        casper.mouse.move '.histogram-bar:first-of-type .bar-people'     
      else
        @mouse.click '.histogram-bar:first-of-type .bar-people'  
        @mouse.move 'body'

      @wait 250, ->
        test.assertSelectorHasText '.pointlist-header-label', 'Pros', "Pros present in pros header when #{state}"
        test.assertSelectorHasText '.pointlist-header-label', 'upport', "Supporter is present in pros header when #{state}"

        @HTMLCapture '[data-role="proposal"]', 
          caption : "#{state} histogram bar"

    # hover over histogram; then click
    casper.then ->
      execute_histogram_tests 'hover'

    casper.then ->
      execute_histogram_tests 'click'


    casper.then ->
      @HTMLStep 'hover over a point'

      @mouse.move 'body'
      point_includers = @evaluate ->
        return _.uniq($('[data-role="point"]:first').attr("includers").split(',')).length

      total_avatars = @evaluate -> return $(".histogram .avatar:visible").length

      @mouse.move '[data-role="point"]'
      @wait 200, ->
        @HTMLCapture '[data-role="proposal"]', 
          caption : "Hovering over a point"

        includers_hidden = @evaluate -> 
          hidden = -> $(this).css('opacity') == '0' || $(this).css('visibility') == 'hidden'
          return $(".histogram .avatar:visible").filter(hidden).length

        test.assertEqual total_avatars - includers_hidden, point_includers, 'Only includers shown on point hover'


    casper.then ->
      test_open_point test

    casper.then ->
      test_browsing_points test

  casper.run ->
    test.done() 


casper.test.begin 'Lurker can poke around the proposal crafting page', 33, (test) ->

  #TODO: loop here, once with logged in user, once without

  casper.start "http://localhost:8787", ->
    @wait(1000).then ->
      @HTMLStep "Crafting page can be navigated to from homepage"
      test.assertExists '[data-role="proposal"] [data-target="craft-position"]', 'Opportunity to add one\'s position'
      @click '[data-role="proposal"]:first-of-type [data-target="craft-position"]:first-of-type'
      @wait 5000, ->
        assert_in_crafting_state test

    casper.then ->
      casper.open("http://localhost:8787/#{example_proposal}/results").wait 5000, ->
        @HTMLStep "Crafting page can be accessed from results page"

        test.assertExists '[data-role="proposal"] [data-target="craft-position"]', 'Opportunity to add one\'s position'
        @click '[data-role="proposal"] [data-target="craft-position"]:first-of-type'
        @wait 5000, ->
          assert_in_crafting_state test

    casper.then ->
      casper.open("http://localhost:8787/#{example_proposal}").wait 5000, ->
        @HTMLStep "Crafting page can be directly opened"

        @HTMLCapture 'body', 
          caption: 'Full crafting page, different sizes'
          sizes: [ [1200, 900], [600, 500], [1024, 768] ]

        assert_in_crafting_state test

    casper.then ->
      test_open_point test

    casper.then ->
      test_browsing_points test

  casper.run ->
    test.done() 

example_user = 262
example_user_with_proposal = 1

casper.test.begin 'Lurker can poke around a user profile', 34, (test) ->
  casper.start "http://localhost:8787/#{example_proposal}", ->

    casper.wait(5000).then ->
      @HTMLStep "Profile page can be accessed from other page"
      test.assertExists '[data-target="user_profile_page"]', 'User profile link exists'
      @click('[data-target="user_profile_page"]:first-of-type')
      casper.wait 5000, ->
        assert_user_profile_loaded test

    casper.then ->      
      casper.open("http://localhost:8787/dashboard/users/#{example_user}/profile").wait 5000, ->
        @HTMLStep "Profile page can be directly opened"

        @HTMLCapture 'body', 
          caption: 'User profile page, different sizes'
          sizes: [ [1200, 900], [600, 500], [1024, 768] ]
        assert_user_profile_loaded test

    casper.then ->
      @HTMLStep "Access points from profile"
      @click('[data-target="points"]')
      casper.wait 200, ->
        test.assertVisible '.dashboard-profile-activity-substance-wrap', 'Has some points listed'
        test.assertVisible '.dashboard-profile-activity-action a', "Has a link to a point"

        entity_id = @evaluate ->             
          return $(".dashboard-profile-activity-action:visible a:first").attr('data-id')

        @click(".dashboard-profile-activity-action a[data-id='#{entity_id}']")

        casper.wait 5000, ->

          assert_point_open test

          casper.back().wait 200, ->
            assert_user_profile_loaded test

    casper.then ->
      casper.open("http://localhost:8787/dashboard/users/#{example_user}/profile").wait 5000, ->
        @HTMLStep "Access positions from profile"
        @click('[data-target="positions"]')
        casper.wait 200, ->
          test.assertVisible '.dashboard-profile-activity-substance-wrap', 'Has some votes listed'
          test.assertVisible '.dashboard-profile-activity-action a', "Has a link to a vote"
          entity_id = @evaluate ->             
            return $(".dashboard-profile-activity-action:visible a:first").attr('data-id')

          @click(".dashboard-profile-activity-action a[data-id='#{entity_id}']")
          casper.wait 5000, ->
            @HTMLCapture 'body', 
              caption: 'Position page, accessed from profile'

            assert_position_open test

            casper.back().wait 200, ->
              assert_user_profile_loaded test

    casper.then ->
      casper.open("http://localhost:8787/dashboard/users/#{example_user_with_proposal}/profile").wait 5000, ->
        @HTMLStep "Access proposals from profile"
        @click('[data-target="proposals"]')
        casper.wait 200, ->
          test.assertVisible '.dashboard-profile-activity-substance-wrap', 'Has some proposals listed'
          test.assertVisible '.dashboard-profile-activity-action a', "Has a link to a proposal"

          entity_id = @evaluate ->             
            return $(".dashboard-profile-activity-action:visible a:first").attr('data-id')

          @click(".dashboard-profile-activity-action a[data-id='#{entity_id}']")

          casper.wait 5000, ->
            assert_in_results_state test

            casper.back().wait 200, ->
              assert_user_profile_loaded test

    casper.then ->
      casper.open("http://localhost:8787/dashboard/users/#{example_user}/profile").wait 5000, ->
        @HTMLStep "Access comments from profile"
        @click('[data-target="comments"]')
        casper.wait 1000, ->
          test.assertVisible '.dashboard-profile-activity-substance-wrap', 'Has some comments listed'
          test.assertVisible '.dashboard-profile-activity-action a', "Has a link to a comment"

          entity_id = @evaluate ->             
            return $(".dashboard-profile-activity-action:visible a:first").attr('data-id')

          @click(".dashboard-profile-activity-action a[data-id='#{entity_id}']")
          casper.wait 5000, ->
            assert_comment_open test, entity_id

            casper.back().wait 200, ->
              assert_user_profile_loaded test


  casper.run ->
    test.done() 

assert_homepage_loaded = (test) ->
  test.assertExists '[data-role="proposal"][data-state="0"]', "there is at least one proposal, and it is collapsed"
  test.assertElementCount '#proposals-container [data-role="proposal"]', 5, "there are 5 active proposals"
  test.assertElementCount '#proposals-container-completed [data-role="proposal"]', 0, "there are no inactive proposals"
  test.assertExists '#proposals-container [data-target="load-proposals"]', 'ability to load more active proposals'
  test.assertExists '#proposals-container-completed [data-target="load-proposals"]', 'ability to load more inactive proposals'

assert_in_results_state = (test) ->
  test.assertExists '[data-role="proposal"][data-state="4"]', 'Proposal is in results state'
  test.assertElementCount '[data-role="proposal"]', 1, "there is only one proposal on the page"
  test.assertVisible '.proposal-details', 'Proposal details are visible'
  test.assertElementCount '.histogram-bar', 7, 'There are seven histogram bars visible'
  test.assertExists '.peer-reasons[data-state="points-together"]', 'Pros and cons in together state'
  test.assertSelectorHasText '.pointlist-header-label', 'Pros', 'Pros present in pros header'
  test.assertSelectorDoesntHaveText '.pointlist-header-label', 'upport', 'Supporter is not present in pros header'

assert_in_crafting_state = (test) ->
  test.assertExists '[data-role="proposal"][data-state="1"]', 'Proposal is in crafting state'
  test.assertElementCount '[data-role="proposal"]', 1, "there is only one proposal on the page"
  test.assertVisible '.proposal-details', 'Proposal details are visible'
  test.assertExists '.position[data-state="separated"]', 'Decision slate is visible'
  test.assertExists '.peer-reasons[data-state="points-separated"]', 'Pros and cons on margins'
  test.assertExists '.stance-slider-container', 'Slider present'
  test.assertElementCount '.point-drop-target', 2, 'Drop targets present'
  test.assertElementCount '.newpoint', 2, 'Add points present'

assert_user_profile_loaded = (test) ->
  test.assertElementCount '.dashboard-profile-activity-summary', 4, "there are four activity blocks"
  test.assertExists '.dashboard-profile-influence-summary', 'There is an influence tracker'

assert_point_open = (test) ->
  test.assertVisible '.point-details-description', 'Point details are visible'
  test.assertVisible '.point-discussion', 'Discussion section exists'

assert_comment_open = (test, comment_id) ->
  assert_point_open test
  test.assertVisible "#comment-#{comment_id}", 'Comment is visible'

assert_position_open = (test) ->
  test.assertVisible '.static-position-reasons', 'Viewing other user position works'

test_open_point = (test) ->
  casper.HTMLStep 'open a point'
  casper.mouse.click '[data-role="point"]'
  casper.wait 1000, ->
    assert_point_open test
    #TODO: if logged in, can thank and comment; if not, cannot thank or comment
    casper.HTMLCapture '.point-expanded', 
      caption : "Expanded point"

    casper.mouse.click '.point-close'
    test.assertDoesntExist '.point-expanded', 'point closes'

test_browsing_points = (test) ->
  casper.HTMLStep 'browse points'
  casper.click '[data-target="browse-toggle"]'

  test.assertExists '.pointlist-browsing', 'entered browsing mode'
  casper.HTMLCapture '.reasons', 
    caption : "Browsing points"

  test.assertVisible '.pointlist-browse-sort', 'user can see the sort option'
  casper.mouse.move '.pointlist-browse-sort-label'

  test.assertVisible '.pointlist-browse-sort-menu', 'user can see the sort menu on hover'

  casper.HTMLCapture '.pointlist-browsing', 
    caption : "Hovering over sort"

  casper.click '.pointlist-browse-sort .pointlist-sort-option [data-target="persuasiveness"]'
  casper.HTMLCapture '.pointlist-browsing', 
    caption : "after clicking persuasiveness sort"

  casper.click '[data-target="browse-toggle"]'
  test.assertDoesntExist '.pointlist-browsing', 'exited browsing mode'
  casper.HTMLCapture '.reasons', 
    caption : "after unexpanding"

