@ConsiderIt.module "Auth", (Auth, App, Backbone, Marionette, $, _) ->
  @startWithParent = false
  
  API =
    password_reset_token : null

    show : ->
      region = App.request 'userNavRegion'
      new Auth.Show.AuthShowController
        region: region

    begin_signin : ->
      if App.request('user:fixed:exists') && !App.request('user:fixed').id
        App.request 'registration:complete_paperwork'
      else
        selected = if !App.request("user:fixed:exists") || App.request("user:fixed").isPersisted() then 'no_pass' else 'pass'
        new Auth.Signin.SigninController
          selected: selected      

    begin_password_reset : ->
      new Auth.Signin.PasswordResetController

    set_password_token : (token) ->
      @password_reset_token = token

    get_password_reset_token : ->
      @password_reset_token

    password_reset_handled : ->
      @password_reset_token = null

    complete_paperwork : (params = {}) -> 
      new Auth.Register.RegisterController
        params : params

    signin : (user_data) ->
      App.request "user:update_current_user", user_data
      App.vent.trigger 'csrf:new', user_data.new_csrf if user_data.new_csrf

      if App.request "user:is_registration_completed?"
        @_handle_signin()
      else
        API.complete_paperwork()

    signout : ->
      $.ajax Routes.destroy_user_session_path(),
        type : 'delete'
        success : (data) =>
          App.vent.trigger 'csrf:new', data.new_csrf
          App.request "user:current:clear"
          API.show()
          App.vent.trigger 'user:signout'

    set_redirect_path_post_signin : (path) ->
      @redirect_after_signin = path

    updateCSRF : (token_val) ->
      $("meta[name='csrf-token']").attr 'content', token_val

    _handle_signin : ->
      API.show()
      App.request 'user:fixed:clear'

      current_user = App.request 'user:current'
      toastr.success "Welcome #{current_user.get('name')}!", null, {positionClass : 'toast-top-middle'}

      # After a user signs in, we're going to query the server and get all the points
      # that this user wrote *anonymously* and proposals they have access to. Then we'll update the data properly so
      # that the user can update them.
      $.get Routes.content_for_user_path(), (data) =>

        App.vent.trigger 'proposals:fetched', data

        App.vent.trigger 'opinions:fetched', data.opinions

        #TODO: check if the appropriate points are updated in all views        
        App.vent.trigger 'points:fetched', 
          (p.point for p in data.points)

        App.vent.trigger 'user:signin:data_loaded'

      if @redirect_after_signin
        App.navigate @redirect_after_signin, {trigger: true}
        @redirect_after_signin = null

      App.vent.trigger 'user:signin'     


  App.reqres.setHandler "auth:reset_password", => 
    API.get_password_reset_token()

  App.reqres.setHandler 'auth:password_reset:handled', =>
    API.password_reset_handled()

  App.reqres.setHandler "user:signin", (user_data, controller = null) ->
    API.signin user_data, controller

  App.reqres.setHandler 'registration:complete_paperwork', (params = {}) -> 
    API.complete_paperwork params

  App.reqres.setHandler 'user:signin:set_redirect', (path) ->
    API.set_redirect_path_post_signin path

  App.vent.on 'signin:requested', -> 
    API.begin_signin()

  App.vent.on 'registration:requested', -> 
    API.begin_registration()

  App.vent.on 'signout:requested', ->
    API.signout()

  App.vent.on 'csrf:new', (token_val) ->
    API.updateCSRF token_val

  Auth.on "start", ->
    API.show()

    API.set_password_token ConsiderIt.password_reset_token
    ConsiderIt.password_reset_token = null

    if API.get_password_reset_token()
      API.begin_password_reset()

    if ConsiderIt.inaccessible_proposal

      @listenToOnce App.vent, 'App:Initialization:Complete', ->
        App.request 'user:signin:set_redirect', Routes.new_opinion_proposal_path(ConsiderIt.inaccessible_proposal.long_id)
        App.navigate Routes.root_path(), {trigger : true}
        toastr.info 'Please sign in first to access this private proposal!'
        App.vent.trigger 'signin:requested'
        ConsiderIt.inaccessible_proposal = null

