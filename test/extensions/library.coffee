create_new_account : (username = 'Testiffer McMuffin', email = 'testy_mctesttest@local.dev', password = '1234567890') ->
  if casper.exists('[action="logout"]')
    logout()

  casper.mouse.click '[action="login"]'
  casper.mouse.click 'input#user_email'
  casper.sendKeys 'input#user_email', email
  casper.mouse.click 'input#password_none'

  casper.mouse.click '[action="create-account"]'

  casper.sendKeys 'input#user_name', username
  casper.sendKeys 'input#user_password', password

  casper.mouse.click 'input#pledge1'
  casper.mouse.click 'input#pledge2'
  casper.mouse.click 'input#pledge3'

  casper.mouse.click '[action="paperwork_complete"]'

login : (email = 'testy_mctesttest@local.dev', password = '1234567890') ->
  if casper.exists('[action="logout"]')
    logout()

  casper.mouse.click '[action="login"]'
  casper.mouse.click '[action="login"]'
  casper.mouse.click 'input#user_email'
  casper.sendKeys 'input#user_email', email
  casper.sendKeys 'input#user_password', password
  casper.mouse.click '[action="login-submit"]'

logout : ->
  if casper.exists('[action="logout"]')
    @mouse.move '.user-options'
    @mouse.click '[action="logout"]'
