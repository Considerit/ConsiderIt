casper = require('casper').create()
casper.options.waitTimeout = 15000

username = casper.cli.get('username')
password = '1234'
host = casper.cli.get('host')

logout = ->
  casper.then ->
    if casper.exists '[action="logout"]'
      casper.echo "Action: starting to log out"
      casper.thenClick '[action="logout"]'
      casper.waitForSelector '[action="login"]', ->
        casper.echo 'Action: logged out'

createAccount = (group = 'public') ->
  logout()

  email = "#{username.replace(' ', '_')}@tigard.consider.it"

  casper.waitUntilVisible '[action="login"]', ->
    casper.echo "Action: starting to create an account #{email}"
  casper.thenClick '[action="login"]'
  casper.waitUntilVisible 'input#user_email'
  casper.thenClick 'input#user_email', ->
    casper.sendKeys 'input#user_email', email
  casper.thenClick 'input#password_none'
  casper.thenClick '[action="create-account"]'
  casper.waitUntilVisible 'input#user_name', ->
    casper.sendKeys 'input#user_name', username
    casper.sendKeys 'input#user_password', password
    #this prevents weird casper/phantomjs error
    casper.capture "lib/tasks/client_data/screens/#{group}.png"    

    casper.thenClick 'input#pledge1'
    casper.thenClick 'input#pledge2'

    #add picture upload!
    casper.then ->   
      casper.evaluate (filename) ->
        __utils__.findOne('#user_avatar[type="file"]').setAttribute('value', filename)
      , "lib/tasks/client_data/profiles/#{group}.png".toLowerCase()

      casper.page.uploadFile 'input#user_avatar[type="file"]', "lib/tasks/client_data/profiles/#{group}.png".toLowerCase()

      casper.capture "lib/tasks/client_data/screens/#{group}2.png"    


    casper.thenClick '[action="paperwork_complete"]'

    casper.waitUntilVisible '.user-options-display', ->
      casper.echo "Action: created account #{email}"
    , ->  casper.capture "lib/tasks/client_data/screens/#{group}fail.png"    



waitUntilStateTransitioned = (state) ->
  casper.waitUntilVisible "[state='#{state}']"
  casper.waitWhileVisible '.transitioning'
  casper.wait 500


casper.start "http://#{host}", ->
  createAccount()
  logout()


casper.run ->
  casper.exit()
 