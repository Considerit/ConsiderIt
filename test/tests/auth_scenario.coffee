require('../library/casper')
require('../library/asserts')

###
Tests authentication. Create a new account. Logout. Then log back in with that account.

Not tested here:
  - user profile picture upload
  - third party authentication
  - proper disabling of buttons in various states
###


###
In future, make sure to test:

registration
- register via email
- register via third party
- user cancels registration after first phase
  = when already exists
  = when new
- register via third party when user already exists

sign in
- sign in via email
- sign in via third party
- sign in via third party when user doesn't yet exist
- forgot password
  = when user doesn't exist
  = when user exists
- when user opens a proposal (but doesn't change their stance), then logs in (with an existing opinion), the opinion should be updated to reflect the user's opinion
- user browses results, not logged in. They even start editing some opinions. Then, on one, they click save, are prompted to login, and do so. Lo & behold, they already have published opinions for this & other proposal they've been actively engaging with.
  + the opinion being edited should be changed to the old, but with the new data subsumed
  + points and other created items this session should have their opinion references updated.
- on signout, clear written points, opinions, reset views

- do from different areas -- on comment, fact check, upper right, submitposition

###

casper.test.begin 'Authentication tests', 9, (test) ->

  casper.start "http://localhost:8787/"

  casper.waitUntilVisible '[action="login"]', ->    
    test.pass "there is an option for logging in"
    @HTMLCapture '[action="login"]', 
      caption: 'Login opportunity'

  # start to create a new account
  casper.thenClick '[action="login"]', ->
    test.assertExists '.auth_overlay', "Create account screen appears"
    @HTMLCapture '.auth_overlay',
      caption: 'login screen'

    @click 'input#password_none'

    casper.fill '.auth_overlay form', 
      'user[email]' : 'testy_mctesttest@local.dev'
    , false

    @HTMLCapture '.auth_overlay',
      caption: 'login screen after input'

  # complete paperwork for new user
  casper.thenClick('[action="create-account"]')
  casper.waitForSelector '.user-accounts-complete-paperwork-form', -> 
    test.assertExists '.user-accounts-complete-paperwork-form', 'Finish paperwork screen appears'

    casper.fill '.auth_overlay form', 
      'user[name]' : 'Testiffer McMuffin'
      'user[password]' : '1234567890'
      'pledge1' : true
      'pledge2' : true
    , false

    @HTMLCapture '.auth_overlay', 
      caption : 'Account paperwork screen'

  # verify logged in
  casper.thenClick('[action="paperwork_complete"]').waitForSelector '.user-options-display', ->
    test.assertLoggedIn()

    @HTMLCapture '#user_nav', 
      caption: 'Nav after login'

  #refresh page to see if still logged in
  casper.reload ->
    @logStep 'Refreshing to check if still logged in'
    @waitForSelector '.user-options-display', ->
      test.assertLoggedIn()


  # logout
  casper.then ->
    @mouse.move '.user-options'

    @waitUntilVisible '[action="logout"]', ->
      @HTMLCapture 'body', 
        caption: 'user dropdown options'

      test.assertVisible '[action="logout"]', 'logout is visible'

      @click '[action="logout"]'

      @waitUntilVisible '[action="login"]', ->
        test.assertLoggedOut()

        @HTMLCapture '#user_nav', 
          caption: 'logged out'

  # now login with that new user
  casper.thenClick('[action="login"]').waitForSelector '.auth_overlay', ->
    test.assertExists '.auth_overlay', "Login screen appears"

    @click 'input#user_email'

    @sendKeys 'input#user_email', 'testy_mctesttest@local.dev'

    @sendKeys 'input#user_password', '1234567890'

    @HTMLCapture '.auth_overlay',
      caption: 'login screen after input'

    @click '[action="login-submit"]'

    @wait 1000, ->
      test.assertExists '.user-options-display', 'User is logged in'

  casper.run ->
    test.done() 
