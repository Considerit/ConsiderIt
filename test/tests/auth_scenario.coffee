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

example_proposal = "wash_i_522"
login_selector = '.save_opinion_button' #'[action="login"]'
auth_area_selector = '.auth_region'

casper.test.begin 'Authentication tests', 9, (test) ->

  casper.start "http://localhost:8787/#{example_proposal}"

  casper.waitUntilVisible login_selector, ->    
    test.pass "there is an option for logging in"
    @HTMLCapture login_selector, 
      caption: 'Login opportunity'

  # start to create a new account
  casper.thenClick login_selector
  casper.waitUntilVisible auth_area_selector, null, -> test.fail 'auth screen never showed up'

  casper.then ->
    test.assertExists auth_area_selector, "Create account screen appears"
    @HTMLCapture auth_area_selector,
      caption: 'login screen'

    casper.sendKeys '#user_name', 'Testiffer McMuffin'
    casper.sendKeys '#user_email', 'testy_mctesttest@local.dev'
    casper.sendKeys '#user_password', '1234567890'
    casper.click '#pledge-1'
    casper.click '#pledge-2'
    casper.click '#pledge-3'

    @HTMLCapture auth_area_selector,
      caption: 'login screen after input'

    test.assertExists '.auth_button'
    
    # complete registration for new user
    casper.click('.auth_button')

  # verify logged in
  casper.waitUntilVisible '[data-action="logout"]', ->
    test.assertLoggedIn()

    @HTMLCapture '.l_header', 
      caption: 'Nav after login'
  , -> test.fail 'Never logged in'


  #refresh page to see if still logged in
  casper.reload ->
    @logStep 'Refreshing to check if still logged in'
    @waitUntilVisible '[data-action="logout"]', -> 
      test.assertLoggedIn()
    , -> test.fail( 'Not logged in after refresh')


  # logout
  casper.then ->
    test.assertVisible '[data-action="logout"]', 'logout is visible'

    @click '[data-action="logout"]'

    @waitWhileVisible '[data-action="logout"]', ->
      test.pass 'logged out successfully'
    , -> test.fail 'did not log out'


    # @mouse.move '.user-options'
    # @waitUntilVisible '[action="logout"]', ->
    #   @HTMLCapture 'body', 
    #     caption: 'user dropdown options'

    #   test.assertVisible '[action="logout"]', 'logout is visible'

    #   @click '[action="logout"]'

    #   @waitUntilVisible '[action="login"]', ->
    #     test.assertLoggedOut()

    #     @HTMLCapture '#user_nav', 
    #       caption: 'logged out'

  # now login with that new user
  casper.thenClick(login_selector).waitForSelector auth_area_selector, ->
    test.assertExists auth_area_selector, "Login screen appears"

    casper.sendKeys '#user_email', 'testy_mctesttest@local.dev'
    casper.sendKeys '#user_password', '1234567890'

    @HTMLCapture auth_area_selector,
      caption: 'login screen after input'

    @click '.auth_button'

    @waitUntilVisible '[data-action="logout"]', -> 
      test.assertLoggedIn()
    , -> test.fail( 'Didn\'t log back in')


  casper.run ->
    test.done() 
