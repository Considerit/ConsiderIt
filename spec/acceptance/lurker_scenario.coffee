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
        
        test.assertExists '[data-role="m-proposal"][data-state="0"]', "there is at least one proposal, and it is collapsed"
        @HTMLCapture '[data-role="m-proposal"]', 
          caption: 'One of the proposals'

        test.assertElementCount '#m-proposals-container [data-role="m-proposal"]', 5, "there are 5 active proposals"
        @HTMLCapture '#m-proposals-container', 
          caption: 'Active proposals'

        test.assertElementCount '#m-proposals-container-completed [data-role="m-proposal"]', 0, "there are no inactive proposals"

        test.assertExists '#m-proposals-container [data-target="load-proposals"]', 'ability to load more active proposals'
        test.assertExists '#m-proposals-container-completed [data-target="load-proposals"]', 'ability to load more inactive proposals'

    casper.then ->
      @HTMLStep "load some more proposals"

      @click '#m-proposals-container [data-target="load-proposals"]'
      @wait 10000, ->
        @HTMLCapture '#m-proposals-container', 
          caption: 'Active proposals'

        test.assertExists '[data-target="proposallist:page"]', 'pagination is shown after loading proposals'
        @HTMLCapture '.m-proposals-operations',
          caption: 'Proposals pagination after loading more'

        @click '#m-proposals-container-completed [data-target="load-proposals"]'
        @wait 10000, ->
          test.assertExists '#m-proposals-container-completed [data-target="proposallist:page"]', 'pagination for inactive proposals is shown after loading inactive proposals'

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
        test.assertExists '[data-role="m-proposal"] .m-peer-reasons[data-state="points-collapsed"]', 'Peer reasons exists in collapsed form'
        @click '[data-role="m-proposal"]:first-of-type .m-peer-reasons[data-state="points-collapsed"]:first-of-type'
        @wait 5000, ->
          @HTMLCapture 'body', 
            caption : 'The results page'

          test.assertExists '[data-role="m-proposal"][data-state="4"]', 'Proposal is in results state'
          test.assertElementCount '[data-role="m-proposal"]', 1, "there is only one proposal on the page"
          test.assertVisible '.m-proposal-details', 'Proposal details are visible'
          test.assertElementCount '.m-histogram-bar', 7, 'There are seven histogram bars visible'
          test.assertExists '.m-peer-reasons[data-state="points-together"]', 'Pros and cons in together state'

          test.assertSelectorHasText '.m-pointlist-header-label', 'Pros', 'Pros present in pros header'
          test.assertSelectorDoesntHaveText '.m-pointlist-header-label', 'upport', 'Supporter is not present in pros header'



    execute_histogram_tests = (state) =>
      @HTMLStep "#{state} histogram"

      if state == 'hover'
        casper.mouse.move '.m-histogram-bar:first-of-type .m-bar-people'     
      else
        @mouse.click '.m-histogram-bar:first-of-type .m-bar-people'  
        @mouse.move 'body'

      @wait 250, ->
        test.assertSelectorHasText '.m-pointlist-header-label', 'Pros', "Pros present in pros header when #{state}"
        test.assertSelectorHasText '.m-pointlist-header-label', 'upport', "Supporter is present in pros header when #{state}"

        @HTMLCapture '[data-role="m-proposal"]', 
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
        return _.uniq($('[data-role="m-point"]:first').attr("includers").split(',')).length

      total_avatars = @evaluate -> return $(".m-histogram .avatar:visible").length

      @mouse.move '[data-role="m-point"]'
      @wait 200, ->
        @HTMLCapture '[data-role="m-proposal"]', 
          caption : "Hovering over a point"

        includers_hidden = @evaluate -> 
          hidden = -> $(this).css('opacity') == '0' || $(this).css('visibility') == 'hidden'
          return $(".m-histogram .avatar:visible").filter(hidden).length

        test.assertEqual total_avatars - includers_hidden, point_includers, 'Only includers shown on point hover'


    casper.then ->
      @HTMLStep 'open a point'
      @mouse.click '[data-role="m-point"]'
      @wait 1000, ->
        test.assertVisible '.m-point-details-description', 'Point details are visible'
        test.assertVisible '.m-point-discussion', 'Discussion section exists'

        #TODO: if logged in, can thank and comment; if not, cannot thank or comment
        @HTMLCapture '.m-point-expanded', 
          caption : "Expanded point"

        @mouse.click '.m-point-close'
        test.assertDoesntExist '.m-point-expanded', 'point closes'

    casper.then ->
      @HTMLStep 'browse points'
      @click '[data-target="browse-toggle"]'

      test.assertExists '.m-pointlist-browsing', 'entered browsing mode'
      @HTMLCapture '.m-reasons', 
        caption : "Browsing points"

      test.assertVisible '.m-pointlist-browse-sort', 'user can see the sort option'
      @mouse.move '.m-pointlist-browse-sort-label'

      test.assertVisible '.m-pointlist-browse-sort-menu', 'user can see the sort menu on hover'

      @HTMLCapture '.m-pointlist-browsing', 
        caption : "Hovering over sort"

      @click '.m-pointlist-browse-sort .m-pointlist-sort-option [data-target="persuasiveness"]'
      @HTMLCapture '.m-pointlist-browsing', 
        caption : "after clicking persuasiveness sort"

      @click '[data-target="browse-toggle"]'
      test.assertDoesntExist '.m-pointlist-browsing', 'exited browsing mode'
      @HTMLCapture '.m-reasons', 
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

