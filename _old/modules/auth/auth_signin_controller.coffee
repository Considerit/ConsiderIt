@ConsiderIt.module "Auth.Signin", (Signin, App, Backbone, Marionette, $, _) ->

  class Signin.SigninController extends App.Controllers.Base
    initialize : (options = {}) ->
      @layout = @getSigninLayout()
      @listenTo @layout, 'show', =>
        @setupLayout @layout

      @dialog_overlay = @getOverlay @layout
      @listenTo @dialog_overlay, 'dialog:canceled', =>
        App.request 'user:current:clear'
        App.vent.trigger 'user:signin:canceled'
        @close()

      @listenTo App.vent, 'user:signin', =>
        @close()

    close : ->
      @dialog_overlay.close() if @dialog_overlay
      @layout.close() if @layout
      super

    setupLayout : (layout) ->
      user = layout.model
      fixed = App.request('user:fixed:exists')

      if fixed && user.authMethod() != 'email'
        provider = switch user.authMethod()
          when 'google'
            'google_oauth2'
          else
            user.authMethod()
        auth_options_view = new Signin.AuthOptions
          model: user
          providers: [ {name: user.authMethod(), provider: provider} ]
          fixed: true
      
      else if (fixed && user.authMethod() != 'email') || !fixed
        auth_options_view = new Signin.AuthOptions
          model: user
          providers: [ {name: 'google', provider: "google_oauth2"}, {name: 'facebook', provider: 'facebook'}, {name: 'twitter', provider: 'twitter'} ]

      if (fixed && user.authMethod() == 'email') || !fixed
        email_view = @setupEmailView
          model: user
          fixed: fixed
          selected : @options.selected
        layout.emailAuthRegion.show email_view

      if auth_options_view
        layout.authOptionsRegion.show auth_options_view        
        @listenTo auth_options_view, 'third_party_auth_request', @handleThirdPartyAuthRequest

    setupEmailView : (options) ->
      email_view = new Signin.ViaEmail
        model: options.model
        fixed: options.fixed
      
      @listenTo email_view, 'passwordReminderRequested', @handlePasswordReminderRequested      
      @listenTo email_view, 'signinCompleted', (data) => @handleSigninCompleted(data, email_view)
      @listenTo email_view, 'emailRegistrationRequested', (params) =>

        $.get Routes.users_check_login_info_path( {email : params.email} ), {}, (data) =>
          if data.valid
            @close()
            App.request 'registration:complete_paperwork', params
          else
            msg = 'An account with that same email address already exists! Please sign in instead.'
            if data.method != 'email'
              msg = "#{msg} Previously you logged in with #{data.method}."
            else
              email_view.toggleInput true

            App.execute 'notify:failure', msg

      email_view

    handleThirdPartyAuthRequest : (provider) ->
      # close this out so that there isn't a conflict with the dialog used for completing paperwork
      @close() 

      App.request 'third_party_auth:new',
        provider : provider
        callback : (user_data) ->
          App.request "user:signin", user_data

    handlePasswordReminderRequested : (email) ->
      $.post Routes.user_password_path(), {user : {email: email}}, (data) =>
        @layout.emailAuthRegion.currentView.respondToPasswordReminderRequest data.result == 'success'

    handleSigninCompleted : (data, view) ->
      if data.result == 'successful'
        data.user = data.user.user
        App.request 'user:signin', data
      else
        view.signinFailed data.reason


    getOverlay : (view) ->
      App.request 'dialog:new', view, 
        class: 'auth_overlay'

    getUser : ->
      if App.request 'user:fixed:exists'
        [App.request('user:fixed'), true]
      else
        [App.request('user:current'), false]


    getSigninLayout : ->
      [user, is_fixed] = @getUser()

      if is_fixed
        new Signin.FixedLayout
          model: user
          fixed: App.request('user:fixed:exists')

      else
        new Signin.Layout
          model: user
          fixed: App.request('user:fixed:exists')



  class Signin.PasswordResetController extends Signin.SigninController
    initialize : ->
      super

      @listenTo @layout, 'before:close', ->
        App.request 'auth:password_reset:handled' 

    setupLayout : (layout) ->
      @listenTo layout, 'reset:complete', (data) => @handleSigninCompleted(data, layout)

    getSigninLayout : ->
      new Signin.PasswordResetView
        model: @getUser()[0]



