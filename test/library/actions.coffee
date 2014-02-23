module.exports = 

  createAccount : (username = 'Testiffer McMuffin', email = 'testy_mctesttest@local.dev', password = '1234567890') ->

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

  login : (email = 'testy_mctesttest@local.dev', password = '1234567890') ->
    casper.mouse.click '[action="login"]'
    casper.waitUntilVisible 'input#user_email', ->
      casper.mouse.click 'input#user_email'
      casper.sendKeys 'input#user_email', email
      casper.sendKeys 'input#user_password', password
      casper.mouse.click '[action="login-submit"]'

  logout : ->
    casper.evaluate ->
      $('[action="logout"]').trigger('click')

    # if casper.exists('[action="logout"]')
    #   casper.mouse.move '.user-options'
    #   casper.mouse.click '[action="logout"]'


