@ConsiderIt.module "Auth", (Auth, App, Backbone, Marionette, $, _) ->
  @startWithParent = false
  
  API =
    show : ->
      region = App.request 'userNavRegion'
      new Auth.Show.Controller
        region: region

    begin_signin : ->
      new Auth.Signin.Controller

    begin_registration : ->
      new Auth.Register.Controller

    begin_password_reset : ->
      new Auth.Signin.PasswordResetController

    get_current_user : ->
      @current_user

    set_current_user : (user) ->
      @current_user = user
      @current_user

    clear_current_user : ->
      API.get_current_user().clear()

    update_current_user : (user_data) ->
      current_user = API.get_current_user()

      if user_data.user.id of ConsiderIt.users
        current_user = API.set_current_user ConsiderIt.users[user_data.user.id] if current_user.id != user_data.user.id
      else if current_user.is_logged_in() 
        ConsiderIt.users[user_data.user.id] = current_user

      current_user.set user_data.user
      current_user.set_follows(user_data.follows) if 'follows' of user_data

      App.vent.trigger 'user:updated'
      if current_user.get 'b64_thumbnail'
        $('head').append("<style>#avatar-#{ConsiderIt.request('user:current').id}{background-image:url('#{ConsiderIt.request('user:current').get('b64_thumbnail')}');}</style>")


    fixed_user : -> 
      if API.fixed_user_exists
        ConsiderIt.limited_user.set 'email', API.fixed_user_email
        ConsiderIt.limited_user
      else
        throw 'Fixed user does not exist'

    fixed_user_email : ->
      ConsiderIt.limited_user_email

    fixed_user_exists : ->
      !!ConsiderIt.limited_user

    password_reset_token : ->
      ConsiderIt.password_reset_token

    password_reset_handled : ->
      ConsiderIt.password_reset_token = null

    complete_paperwork : (controller = null) -> 
      controller ?= API.begin_registration()
      App.vent.trigger 'registration:complete_paperwork'


    signin : (user_data, controller = null) ->
      API.update_current_user user_data

      user = App.request 'user:current'
      if user.paperwork_completed() 
        API.show()
        App.vent.trigger 'user:signin'              
      else
        API.complete_paperwork controller

    signout : ->
      $.get Routes.destroy_user_session_path(), (data) =>
        ConsiderIt.utils.update_CSRF(data.new_csrf)
        API.clear_current_user()
        API.show()
        App.vent.trigger 'user:signout'


  App.reqres.setHandler "user:current", ->
    API.get_current_user()

  App.reqres.setHandler "user:current:set", (user) ->
    API.set_current_user user

  App.reqres.setHandler "user:current:clear", ->
    API.clear_current_user()

  App.reqres.setHandler "user:current:update", (user_data) ->
    API.update_current_user user_data

  App.reqres.setHandler "user:fixed", ->
    API.fixed_user()

  App.reqres.setHandler "user:fixed:email", ->
    API.fixed_user_email()

  App.reqres.setHandler "user:fixed:exists", ->
    API.fixed_user_exists()

  App.reqres.setHandler "user:reset_password", => 
    API.password_reset_token()

  App.reqres.setHandler 'user:password_reset:handled', =>
    API.password_reset_handled()

  App.reqres.setHandler "user:signin", (user_data, controller = null) ->
    API.signin user_data, controller

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

  App.on 'initialize:before', ->
    API.set_current_user(ConsiderIt.request('user:current') || new ConsiderIt.User())

    if ConsiderIt.current_user_data
      API.update_current_user ConsiderIt.current_user_data
      ConsiderIt.current_user_data = null

  Auth.on "start", ->
    API.show()

    if token = API.password_reset_token()
      API.begin_password_reset()