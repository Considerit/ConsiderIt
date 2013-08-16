@ConsiderIt.module "Auth", (Auth, App, Backbone, Marionette, $, _) ->
  @startWithParent = false
  
  API =
    show : ->
      region = App.request 'userNavRegion'
      new Auth.Show.Controller
        region: region

    begin_signin : ->
      if !API.fixed_user_exists() || API.fixed_user.isPersisted()
        new Auth.Signin.Controller
      else
        API.begin_registration()

    begin_registration : ->
      if !API.fixed_user_exists() || !API.fixed_user.isPersisted()
        new Auth.Register.Controller
      else
        API.begin_signin()

    begin_password_reset : ->
      new Auth.Signin.PasswordResetController

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
        @_handle_signin()         
      else
        API.complete_paperwork controller

    signout : ->
      $.get Routes.destroy_user_session_path(), (data) =>
        ConsiderIt.utils.update_CSRF(data.new_csrf)
        API.clear_current_user()
        API.show()
        App.vent.trigger 'user:signout'

    set_redirect_path_post_signin : (path) ->
      @redirect_after_signin = path

    _handle_signin : ->
      API.show()
      App.request 'user:fixed:clear'
      if @redirect_after_signin
        App.navigate @redirect_after_signin, {trigger: true}
        @redirect_after_signin = null

      # After a user signs in, we're going to query the server and get all the points
      # that this user wrote *anonymously* and proposals they have access to. Then we'll update the data properly so
      # that the user can update them.
      $.get Routes.content_for_user_path(), (data) =>
        proposals = App.request 'proposals:get'
        proposals.set data.proposals

        for pnt in data.points
          [id, long_id, is_pro] = [pnt.point.id, pnt.point.long_id, pnt.point.is_pro]
          proposal = App.request 'proposal:get', long_id
          #TODO: need to accommodate this
          proposal.update_anonymous_point(id, is_pro) if proposal && proposal.data_loaded

      App.vent.trigger 'user:signin'     




  App.reqres.setHandler "auth:reset_password", => 
    API.password_reset_token()

  App.reqres.setHandler 'auth:password_reset:handled', =>
    API.password_reset_handled()

  App.reqres.setHandler "user:signin", (user_data, controller = null) ->
    API.signin user_data, controller

  App.reqres.setHandler 'registration:complete_paperwork', (controller = null) -> 
    API.complete_paperwork controller

  App.reqres.setHandler 'user:signin:set_redirect', (path) ->
    API.set_redirect_path_post_signin path

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

    if token = API.password_reset_token()
      API.begin_password_reset()