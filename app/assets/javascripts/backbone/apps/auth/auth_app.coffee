@ConsiderIt.module "Auth", (Auth, App, Backbone, Marionette, $, _) ->
  @startWithParent = false
  
  API =
    show : ->
      region = App.request 'userNavRegion'
      new Auth.Show.Controller
        region: region

    begin_signin : ->
      if !API.fixed_user_exists() || API.fixed_user.is_persisted()
        new Auth.Signin.Controller
      else
        API.begin_registration()

    begin_registration : ->
      if !API.fixed_user_exists() || !API.fixed_user.is_persisted()
        new Auth.Register.Controller
      else
        API.begin_signin()

    begin_password_reset : ->
      new Auth.Signin.PasswordResetController

    get_current_user : ->
      @current_user

    set_current_user : (user) ->
      @current_user = user
      @current_user

    current_user_logged_in : ->
      API.get_current_user().is_persisted()

    clear_current_user : ->
      API.get_current_user().clear()

    update_current_user : (user_data) ->
      current_user = API.get_current_user()

      if user_data.user.id of ConsiderIt.users
        current_user = API.set_current_user ConsiderIt.users[user_data.user.id] if current_user.id != user_data.user.id
      else if ConsiderIt.request "user:current:logged_in?"
        ConsiderIt.users[user_data.user.id] = current_user

      current_user.set user_data.user
      current_user.set_follows(user_data.follows) if 'follows' of user_data

      if current_user.get 'b64_thumbnail'
        $('head').append("<style>#avatar-#{ConsiderIt.request('user:current').id}{background-image:url('#{ConsiderIt.request('user:current').get('b64_thumbnail')}');}</style>")

      App.vent.trigger 'user:updated'


    fixed_user : -> 
      if API.fixed_user_exists
        ConsiderIt.limited_user
      else
        throw 'Fixed user does not exist'

    fixed_user_exists : ->
      !!ConsiderIt.limited_user

    clear_fixed_user : ->
      if API.fixed_user_exists()
        ConsiderIt.limited_user = null

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
      API.clear_fixed_user()
      if @redirect_after_signin
        App.router.navigate @redirect_after_signin, {trigger: true}
        @redirect_after_signin = null

      # After a user signs in, we're going to query the server and get all the points
      # that this user wrote *anonymously* and proposals they have access to. Then we'll update the data properly so
      # that the user can update them.
      $.get Routes.content_for_user_path(), (data) =>
        for proposal in data.proposals
          ConsiderIt.all_proposals.add_proposals (p for p in data.proposals)

        for pnt in data.points
          [id, long_id, is_pro] = [pnt.point.id, pnt.point.long_id, pnt.point.is_pro]
          proposal = ConsiderIt.all_proposals.findWhere( {long_id : long_id} )
          proposal.update_anonymous_point(id, is_pro) if proposal && proposal.data_loaded

      App.vent.trigger 'user:signin'     

  App.reqres.setHandler "user:current", ->
    API.get_current_user()

  App.reqres.setHandler "user:current:set", (user) ->
    API.set_current_user user

  App.reqres.setHandler "user:current:clear", ->
    API.clear_current_user()

  App.reqres.setHandler "user:current:update", (user_data) ->
    API.update_current_user user_data

  App.reqres.setHandler "user:current:logged_in?", ->
    API.current_user_logged_in()

  App.reqres.setHandler "user:fixed", ->
    API.fixed_user()

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

  App.on 'initialize:before', ->
    API.set_current_user(ConsiderIt.request('user:current') || new ConsiderIt.User())

    if ConsiderIt.current_user_data
      API.update_current_user ConsiderIt.current_user_data
      ConsiderIt.current_user_data = null

  Auth.on "start", ->
    API.show()

    if token = API.password_reset_token()
      API.begin_password_reset()