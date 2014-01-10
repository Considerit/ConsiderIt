casper.test.begin 'Homepage can be mucked around', 2, (test) ->
  casper.start "http://localhost:8787/", ->

    casper.wait 500, ->

      test.assertTitle "Living Voters Guide: 2013 Washington Election", "homepage title is the one expected"
      test.assertExists '[data-role="m-proposal"]', "there are proposals"

      for [width, height] in [ [600, 500], [1024, 768], [1200, 900]]
        @viewport width, height
        @captureSelector "screen-#{width}x#{height}.png", 'body' 

    # this.fill('form[action="/search"]', {
    #   q: "casperjs"
    # }, true)

  # casper.then ->
  #   test.assertTitle("casperjs - Recherche Google", "google title is ok")
  #   test.assertUrlMatch(/q=casperjs/, "search term has been submitted")
  #   test.assertEval ->
  #     return __utils__.findAll("h3.r").length >= 10
  #   , "google search for \"casperjs\" retrieves 10 or more results"

  casper.run ->
    test.done() 
