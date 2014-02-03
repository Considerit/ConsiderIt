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
###


casper.test.begin 'Lurker can poke around homepage', 7, (test) ->

  #TODO: loop here, once with logged in user, once without
  casper.start "http://localhost:8787/", ->

    casper.then ->
      casper.wait 1000, ->
        @HTMLStep "Homepage can be mucked about"

        @HTMLCapture 'body', 
          caption: 'Full homepage, different sizes'
          sizes: [ [1200, 900], [600, 500], [1024, 768] ]
        
        test.assertExists '[data-role="proposal"][data-state="0"]', "there is at least one proposal, and it is collapsed"
        @HTMLCapture '[data-role="proposal"]', 
          caption: 'One of the proposals'

        test.assertElementCount '#proposals-container [data-role="proposal"]', 5, "there are 5 active proposals"
        @HTMLCapture '#proposals-container', 
          caption: 'Active proposals'

        test.assertElementCount '#proposals-container-completed [data-role="proposal"]', 0, "there are no inactive proposals"

        test.assertExists '#proposals-container [data-target="load-proposals"]', 'ability to load more active proposals'
        test.assertExists '#proposals-container-completed [data-target="load-proposals"]', 'ability to load more inactive proposals'

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

  casper.run ->
    test.done() 



casper.test.begin 'Lurker can poke around a proposal results page', 20, (test) ->

  #TODO: loop here, once with logged in user, once without
  casper.start "http://localhost:8787/", ->

    #TODO: loop, once going to active proposal, next to an inactive proposal
    #TODO: loop, proposal with activity and without activity

    casper.then -> 
      @wait 1000, ->

        @HTMLStep 'browse to a proposal results page'
        test.assertExists '[data-role="proposal"] .peer-reasons[data-state="points-collapsed"]', 'Peer reasons exists in collapsed form'
        @click '[data-role="proposal"]:first-of-type .peer-reasons[data-state="points-collapsed"]:first-of-type'
        @wait 5000, ->
          @HTMLCapture 'body', 
            caption : 'The results page'

          test.assertExists '[data-role="proposal"][data-state="4"]', 'Proposal is in results state'
          test.assertElementCount '[data-role="proposal"]', 1, "there is only one proposal on the page"
          test.assertVisible '.proposal-details', 'Proposal details are visible'
          test.assertElementCount '.histogram-bar', 7, 'There are seven histogram bars visible'
          test.assertExists '.peer-reasons[data-state="points-together"]', 'Pros and cons in together state'

          test.assertSelectorHasText '.pointlist-header-label', 'Pros', 'Pros present in pros header'
          test.assertSelectorDoesntHaveText '.pointlist-header-label', 'upport', 'Supporter is not present in pros header'



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
      @HTMLStep 'open a point'
      @mouse.click '[data-role="point"]'
      @wait 1000, ->
        test.assertVisible '.point-details-description', 'Point details are visible'
        test.assertVisible '.point-discussion', 'Discussion section exists'

        #TODO: if logged in, can thank and comment; if not, cannot thank or comment
        @HTMLCapture '.point-expanded', 
          caption : "Expanded point"

        @mouse.click '.point-close'
        test.assertDoesntExist '.point-expanded', 'point closes'

    casper.then ->
      @HTMLStep 'browse points'
      @click '[data-target="browse-toggle"]'

      test.assertExists '.pointlist-browsing', 'entered browsing mode'
      @HTMLCapture '.reasons', 
        caption : "Browsing points"

      test.assertVisible '.pointlist-browse-sort', 'user can see the sort option'
      @mouse.move '.pointlist-browse-sort-label'

      test.assertVisible '.pointlist-browse-sort-menu', 'user can see the sort menu on hover'

      @HTMLCapture '.pointlist-browsing', 
        caption : "Hovering over sort"

      @click '.pointlist-browse-sort .pointlist-sort-option [data-target="persuasiveness"]'
      @HTMLCapture '.pointlist-browsing', 
        caption : "after clicking persuasiveness sort"

      @click '[data-target="browse-toggle"]'
      test.assertDoesntExist '.pointlist-browsing', 'exited browsing mode'
      @HTMLCapture '.reasons', 
        caption : "after unexpanding"

  casper.run ->
    test.done() 


# casper.test.begin 'Lurker can poke around the proposal crafting page', 2, (test) ->

#     # casper.then -> 
#     #   # browse to a proposal crafting page

#     #   # open a point

#     #   # browse points

#   casper.run ->
#     test.done() 

# casper.test.begin 'Lurker can poke around a user profile', 2, (test) ->

#     # casper.then ->
#     #   # check out a user's profile page

#   casper.run ->
#     test.done() 

