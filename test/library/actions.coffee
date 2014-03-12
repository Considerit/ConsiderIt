module.exports = 

  createAccount : (username = 'Testiffer McMuffin', email = 'testy_mctesttest@local.dev', password = '1234567890') ->

    casper.wait 500, ->
      casper.click '[action="login"]'
      casper.waitUntilVisible 'input#user_email', ->
        casper.click 'input#user_email'
        casper.sendKeys 'input#user_email', email
        casper.click 'input#password_none'
        casper.click '[action="create-account"]'
        casper.waitUntilVisible 'input#user_name', ->
          casper.sendKeys 'input#user_name', username
          casper.sendKeys 'input#user_password', password
          casper.click 'input#pledge1'
          casper.click 'input#pledge2'
          casper.click '[action="paperwork_complete"]'

  login : (email = 'testy_mctesttest@local.dev', password = '1234567890') ->
    casper.thenClick '[action="login"]', ->
      casper.waitUntilVisible 'input#user_email', ->
        casper.click 'input#user_email'
        casper.sendKeys 'input#user_email', email
        casper.sendKeys 'input#user_password', password
        casper.click '[action="login-submit"]'

  loginAsAdmin : ->
    module.exports.logout()
    module.exports.login 'admin@consider.it', 'test'

  logout : ->
    casper.then ->
      casper.evaluate ->
        $('[action="logout"]').trigger('click')