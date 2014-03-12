module.exports = 

  createAccount : (username = 'Testiffer McMuffin', email = 'testy_mctesttest@local.dev', password = '1234567890') ->

    casper.wait 500, ->
      casper.click '[action="login"]'
      casper.waitUntilVisible 'input#user_email', ->
        casper.thenClick 'input#user_email', ->
          casper.sendKeys 'input#user_email', email
        casper.thenClick 'input#password_none'
        casper.thenClick '[action="create-account"]'
        casper.waitUntilVisible 'input#user_name', ->
          casper.sendKeys 'input#user_name', username
          casper.sendKeys 'input#user_password', password
          casper.thenClick 'input#pledge1'
          casper.thenClick 'input#pledge2'
          casper.thenClick '[action="paperwork_complete"]'

  login : (email = 'testy_mctesttest@local.dev', password = '1234567890') ->
    module.exports.logout()

    casper.thenClick '[action="login"]'
    casper.waitUntilVisible 'input#user_email'
    casper.thenClick 'input#user_email', ->
      casper.sendKeys 'input#user_email', email
      casper.sendKeys 'input#user_password', password
    casper.thenClick '[action="login-submit"]'
    casper.waitUntilVisible '.user-options-display'

  loginAsAdmin : ->
    module.exports.login 'admin@consider.it', 'test'

  logout : ->
    casper.then ->
      if casper.exists '[action="logout"]'
        casper.thenClick '[action="logout"]'