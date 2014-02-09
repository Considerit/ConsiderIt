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

###

casper.test.begin 'Authentication tests', 8, (test) ->

  casper.start "http://localhost:8787/", ->

    casper.wait 1000, ->
      
      casper.then ->
        test.assertExists '[data-target="login"]', "there is an option for logging in"
        casper.HTMLCapture '[data-target="login"]', 
          caption: 'Login opportunity'


      casper.then ->
        # start to create a new account
        @mouse.click '[data-target="login"]'
        test.assertExists '.auth_overlay', "Create account screen appears"
        @HTMLCapture '.auth_overlay',
          caption: 'login screen'

        @mouse.click 'input#user_email'

        @sendKeys 'input#user_email', 'testy_mctesttest@local.dev'


        @mouse.click 'input#password_none'

        @HTMLCapture '.auth_overlay',
          caption: 'login screen after input'

        @mouse.click '[data-target="create-account"]'

      casper.then -> 
        # complete paperwork for new user
        test.assertExists '.user-accounts-complete-paperwork-form', 'Finish paperwork screen appears'

        @sendKeys 'input#user_name', 'Testiffer McMuffin'

        @sendKeys 'input#user_password', '1234567890'

        @mouse.click 'input#pledge1'
        @mouse.click 'input#pledge2'
        @mouse.click 'input#pledge3'

        @HTMLCapture '.auth_overlay', 
          caption : 'Account paperwork screen'

        @mouse.click '[data-target="paperwork_complete"]'

      casper.then ->
        # verify logged in
        casper.wait 1000, ->
          test.assertExists '.user-options-display', 'User is logged in'

          @HTMLCapture '#user-nav', 
            caption: 'Nav after login'


      casper.then ->
        # logout

        @mouse.move '.user-options'

        casper.wait 500, ->
          @HTMLCapture 'body', 
            caption: 'user dropdown options'

          test.assertVisible '[data-target="logout"]', 'logout is visible'

          @mouse.click '[data-target="logout"]'

          casper.wait 1000, ->
            test.assertExists '[data-target="login"]', 'User has successfully logged out'
            @HTMLCapture '#user-nav', 
              caption: 'logged out'

      casper.then ->
        # now login with that new user
        @mouse.click '[data-target="login"]'
        test.assertExists '.auth_overlay', "Login screen appears"

        @mouse.click 'input#user_email'

        @sendKeys 'input#user_email', 'testy_mctesttest@local.dev'

        @sendKeys 'input#user_password', '1234567890'

        @HTMLCapture '.auth_overlay',
          caption: 'login screen after input'

        @mouse.click '[data-target="login-submit"]'

        casper.wait 1000, ->
          test.assertExists '.user-options-display', 'User is logged in'




  casper.run ->
    test.done() 
