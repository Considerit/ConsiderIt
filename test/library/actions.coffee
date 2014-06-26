require('../library/casper')

module.exports = 

  # loops through the given test (callback), first when logged out and second when logged in
  executeLoggedInAndLoggedOut : (location, callback) ->
    casper.start location

    module.exports.logout()

    casper.then ->
      callback.call casper, false # run tests while not logged in

    module.exports.logout()

    casper.thenOpen location, ->
      casper.waitUntilVisible '#content', ->
        if casper.exists '[action="login"]'
          casper.then ->
            id = Math.floor((Math.random()*100000)+1)
            module.exports.createAccount "testy_mctesttest_#{id}@testing.dev", "Testy #{id}", '123124124243'

          casper.waitUntilVisible '.user-options-display', ->
            callback.call casper, true # run tests while logged in
          , -> casper.logAction "FAILED! Could not create account", 'ERROR'
        else
          callback.call casper, true
      , -> casper.logAction "FAILED! could not open #{location}", 'ERROR'

    module.exports.logout()


  createAccount : (email = 'testy_mctesttest@local.dev', username = 'Testiffer McMuffin', password = '1234567890') ->

    module.exports.logout()

    casper.waitUntilVisible '[action="login"]', ->
      casper.logAction "Action: starting to create an account #{email}"
    casper.thenClick '[action="login"]'
    casper.waitUntilVisible 'input#user_email', null, -> casper.logAction "FAILED! login dialog never appears", 'ERROR'
    casper.thenClick 'input#password_none', ->
      casper.fill '.auth_overlay form', 
        'user[email]' : email
      , false
      casper.thenClick '[action="create-account"]'
    

    casper.waitUntilVisible 'input#user_name', ->

      casper.fill '.auth_overlay form', 
        'user[name]' : username
        'user[password]' : password
        'pledge1' : true
        'pledge2' : true
      , false

      casper.thenClick '[action="paperwork_complete"]'

      casper.waitUntilVisible '.user-options-display', ->
        casper.logAction "Action: created account #{email}"
      , ->
        casper.logAction "FAILED! create account #{email}", 'ERROR'

      # # for some reason I can't figure out, this WAIT is needed
      # # in the Proposer scenario
      # casper.wait 500 
    , ->
      casper.logAction "FAILED! never leave create account screen for #{email}", 'ERROR'

  login : (email = 'testy_mctesttest@local.dev', password = '1234567890') ->
    module.exports.logout()

    casper.thenClick '[action="login"]', ->
      casper.logAction "Action: starting to log in #{email}"

    casper.waitUntilVisible 'input#user_email', null, -> casper.logAction "FAILED! login dialog never appears", 'ERROR'

    casper.then ->
      casper.fill '.auth_overlay form', 
        'user[email]' : email, 
        'user[password]' : password
      , false

    casper.thenClick '[action="login-submit"]'
    casper.waitUntilVisible '.user-options-display', ->
      casper.logAction 'Action: Logged in'
    , -> casper.logAction "FAILED! never logged in for #{email}", 'ERROR' 

  loginAsAdmin : ->
    module.exports.login 'admin@consider.it', 'test'

  logout : ->
    casper.then ->
      if casper.exists '[action="logout"]'
        casper.logAction "Action: starting to log out"
        casper.thenClick '[action="logout"]'
        casper.waitForSelector '[action="login"]', ->
          casper.logAction 'Action: logged out'
        , -> casper.logAction "FAILED! didn't successfully log out", 'ERROR'

