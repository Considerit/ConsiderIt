casper.test.begin 'Homepage can be mucked around', 2, (test) ->

  casper.start "http://localhost:8787/", ->

    casper.wait 500, ->

      casper.HTMLCapture 'body', 
        caption: 'Full homepage, different sizes'
        sizes: [ [1200, 900], [600, 500], [1024, 768] ]

      test.assertTitle "Living Voters Guide: 2013 Washington Election", "homepage title is the one expected"

      
      test.assertExists '[data-role="m-proposal"]', "there are proposals"
      casper.HTMLCapture '[data-role="m-proposal"]', 
        caption: 'One of the proposals'


  casper.run ->
    test.done() 
