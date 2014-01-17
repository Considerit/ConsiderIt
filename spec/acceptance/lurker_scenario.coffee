
casper.test.begin 'Homepage can be mucked around', 2, (test) ->

  casper.start "http://localhost:8787/", ->

    casper.wait 500, ->

      test.assertTitle "Living Voters Guide: 2013 Washington Election", "homepage title is the one expected"

      casper.HTMLCapture()
      
      test.assertExists '[data-role="m-proposal"]', "there are proposals"
      casper.HTMLCapture '[data-role="m-proposal"]', 
        caption: 'One of the proposals'


  casper.run ->
    test.done() 
