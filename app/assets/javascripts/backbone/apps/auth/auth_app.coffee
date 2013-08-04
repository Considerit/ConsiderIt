@ConsiderIt.module "Auth", (Auth, App, Backbone, Marionette, $, _) ->
  @startWithParent = false
  
  API =
    show: ->
      region = App.request 'userNavRegion'
      new Auth.Show.Controller
        region: region

    begin_signin: ->
      new Auth.Signin.Controller

    begin_registration: ->
      new Auth.Register.Controller

    current_user: ->
      ConsiderIt.current_user

    fixed_user: -> 
      if API.fixed_user_exists
        ConsiderIt.limited_user.set 'email', API.fixed_user_email
        ConsiderIt.limited_user
      else
        throw 'Fixed user does not exist'

    fixed_user_email: ->
      ConsiderIt.limited_user_email

    fixed_user_exists: ->
      !!ConsiderIt.limited_user

    complete_paperwork: (controller = null) -> 
      controller ?= API.begin_registration()
      App.vent.trigger 'registration:complete_paperwork'


    signin: (user_data, controller = null) ->
      ConsiderIt.update_current_user user_data

      user = App.request 'user:current'
      if user.paperwork_completed() 
        if not user.id of ConsiderIt.users
          ConsiderIt.users[user.id] = user

        API.show()
        App.vent.trigger 'user:signin'              
      else
        API.complete_paperwork controller

    signout: ->
      $.get Routes.destroy_user_session_path(), (data) =>
        ConsiderIt.utils.update_CSRF(data.new_csrf)
        ConsiderIt.clear_current_user()
        API.show()
        App.vent.trigger 'user:signout'


  App.reqres.setHandler "user:current", ->
    API.current_user()

  App.reqres.setHandler "user:fixed", ->
    API.fixed_user()

  App.reqres.setHandler "user:fixed:email", ->
    API.fixed_user_email()

  App.reqres.setHandler "user:fixed:exists", ->
    API.fixed_user_exists()

  App.reqres.setHandler "user:signin", (user_data, controller = null) ->
    API.signin(user_data, controller)

  App.reqres.setHandler 'registration:complete_paperwork', (controller = null) -> 
    API.complete_paperwork controller

  App.vent.on 'signin:requested', -> 
    API.begin_signin()  

  App.vent.on 'registration:requested', -> 
    API.begin_registration()

  App.vent.on 'signout:requested', ->
    API.signout()

  # App.vent.on 'user:updated', => 
  #   API.show()

  Auth.on "start", ->
    API.show()