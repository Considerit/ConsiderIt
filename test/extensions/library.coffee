casper.ConsiderIt = {}

casper.ConsiderIt.createNewAccount = (username = 'Testiffer McMuffin', email = 'testy_mctesttest@local.dev', password = '1234567890') ->

  casper.wait 500, ->

    casper.mouse.click '[action="login"]'

    casper.waitUntilVisible 'input#user_email', ->

      casper.mouse.click 'input#user_email'
      casper.sendKeys 'input#user_email', email
      casper.mouse.click 'input#password_none'

      casper.mouse.click '[action="create-account"]'

      casper.waitUntilVisible 'input#user_name', ->

        casper.sendKeys 'input#user_name', username
        casper.sendKeys 'input#user_password', password

        casper.mouse.click 'input#pledge1'
        casper.mouse.click 'input#pledge2'

        casper.mouse.click '[action="paperwork_complete"]'

casper.ConsiderIt.login = (email = 'testy_mctesttest@local.dev', password = '1234567890') ->
  casper.mouse.click '[action="login"]'
  casper.waitUntilVisible 'input#user_email', ->
    casper.mouse.click 'input#user_email'
    casper.sendKeys 'input#user_email', email
    casper.sendKeys 'input#user_password', password
    casper.mouse.click '[action="login-submit"]'

casper.ConsiderIt.logout = ->
  casper.evaluate ->
    $('[action="logout"]').trigger('click')

  # if casper.exists('[action="logout"]')
  #   casper.mouse.move '.user-options'
  #   casper.mouse.click '[action="logout"]'


casper.ExecuteLoggedInAndLoggedOut = (location, callback) ->

  casper.start location, ->

    casper.then -> 
      casper.wait(5000).then -> 
        casper.ConsiderIt.logout()

      casper.then ->
        callback false # run tests while not logged in

    casper.then ->
      casper.open(location).waitUntilVisible '#l_wrap', ->
        if casper.exists '[action="login"]'
          casper.then ->
            id = Math.floor((Math.random()*100000)+1)
            casper.ConsiderIt.createNewAccount "Testy #{id}", "testy_mctesttest_#{id}@testing.dev", '123124124243'

          casper.wait 2500, ->
            callback true # run tests while logged in
        else
          callback true

