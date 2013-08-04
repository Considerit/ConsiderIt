@ConsiderIt.module "Auth.Signin", (Signin, App, Backbone, Marionette, $, _) ->

  class Signin.Controller extends App.Controllers.Base
    initialize : ->
      @layout = @getSigninLayout()
      @listenTo @layout, 'show', =>
        @setupLayout @layout

      @dialog_overlay = @getOverlay @layout
      @listenTo @dialog_overlay, 'dialog:canceled', =>
        ConsiderIt.current_user.clear()
        @layout.close()
        @close()

      @listenTo App.vent, 'user:signin', =>
        @layout.close()
        @dialog_overlay.close()
        @close()


    setupLayout : (layout) ->
      user = layout.model

      if App.request 'user:fixed:exists'
        if user.auth_method() == 'email'
          email_view = @setupEmailView
            model: user
            fixed: true
          layout.emailAuthRegion.show email_view

        else
          auth_options_view = new Signin.AuthOptions
            model: user
            providers: [ {name: user.auth_method()} ]
          layout.authOptionsRegion.show auth_options_view

      else
        
        auth_options_view = new Signin.AuthOptions
          model: user
          providers: [ {name: 'email'}, {name: 'google'}, {name: 'facebook'}, {name: 'twitter'} ]

        @listenTo auth_options_view, 'email_auth_request', ->
          email_view = @setupEmailView
            model: user
            fixed: false
          layout.authOptionsRegion.close()
          layout.emailAuthRegion.show email_view

        layout.authOptionsRegion.show auth_options_view

      @listenTo auth_options_view, 'third_party_auth_request', @handleThirdPartyAuthRequest

    setupEmailView : (options) ->
      email_view = new Signin.ViaEmail
        model: options.user
        fixed: options.fixed
      
      @listenTo email_view, 'passwordReminderRequested', @handlePasswordReminderRequested      
      @listenTo email_view, 'signinCompleted', @handleSigninCompleted

      email_view

    handleThirdPartyAuthRequest : (provider) ->
      # handle setting up third party request...
      App.request 'third_party_auth:new',
        provider : provider
        callback : (user_data) ->
          App.request "user:signin", user_data

    handlePasswordReminderRequested : (email) ->
      $.post Routes.user_password_path(), {user : {email: email}}, (data) =>
        email_view.respondToPasswordReminderRequest data.result == 'success'

    handleSigninCompleted : (data) =>
      if data.result == 'successful'
        data.user = data.user.user
        App.request 'user:signin', data
      else
        email_view.signinFailed data.reason


    getOverlay : (view) ->
      App.request 'dialog:new', view, 
        class: 'auth_overlay'

    getSigninLayout : ->

      if App.request 'user:fixed:exists'
        user = App.request 'user:fixed'
      else
        user = App.request 'user:current'

      layout = new Signin.Layout
        model: user

      layout
      # signinview.render()
      # signinview.$el.bind 'destroyed', () => 
      #   App.request 'dialog:close'
      #   #@post_signin()

      #signinview


