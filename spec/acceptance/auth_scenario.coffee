casper.test.begin 'Authentication tests', 2, (test) ->

  casper.start "http://localhost:8787/", ->

    casper.wait 500, ->
      
      test.assertExists '[data-target="login"]', "there is an option for logging in"
      casper.HTMLCapture '[data-target="login"]', 
        caption: 'Login opportunity'

      test.assertExists '[data-target="NOT EHRE"]', 'blatently failing'


  casper.run ->
    test.done() 
