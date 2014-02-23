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
  casper.start location

  casper.wait 5000, -> 
    casper.ConsiderIt.logout()

  casper.then ->
    callback.call casper, false # run tests while not logged in

  casper.thenOpen(location).waitUntilVisible '#l_wrap', ->
    if casper.exists '[action="login"]'
      casper.then ->
        id = Math.floor((Math.random()*100000)+1)
        casper.ConsiderIt.createNewAccount "Testy #{id}", "testy_mctesttest_#{id}@testing.dev", '123124124243'

      casper.wait 2500, ->
        callback.call casper, true # run tests while logged in
    else
      callback.call casper, true

casper.waitUntilStateTransitioned = (state, callback) ->
  casper.waitUntilVisible "[state='#{state}']", ->
    casper.waitWhileVisible '.transitioning', ->
      casper.wait 200, ->
        callback.call casper



