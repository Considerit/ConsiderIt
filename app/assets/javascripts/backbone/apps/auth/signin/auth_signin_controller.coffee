@ConsiderIt.module "Auth.Signin", (Signin, App, Backbone, Marionette, $, _) ->

  class Signin.Controller extends App.Controllers.Base
    initialize : ->
      @layout = @getSigninLayout()
      @listenTo @layout, 'show', =>
        @setupLayout @layout

      @dialog_overlay = @getOverlay @layout
      @listenTo @dialog_overlay, 'dialog:canceled', =>
        App.request 'user:current:clear'
        @close()

      @listenTo App.vent, 'user:signin', =>
        @close()

    close : ->
      @dialog_overlay.close()
      @layout.close()
      super

    setupLayout : (layout) ->
      user = layout.model

      if App.request 'user:fixed:exists'
        if user.authMethod() == 'email'
          email_view = @setupEmailView
            model: user
            fixed: true
          layout.emailAuthRegion.show email_view

        else
          auth_options_view = new Signin.AuthOptions
            model: user
            providers: [ {name: user.authMethod()} ]
            fixed: true
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

        @listenTo auth_options_view, 'switch_method_requested', ->
          @close()
          App.vent.trigger 'registration:requested'

        layout.authOptionsRegion.show auth_options_view

      @listenTo auth_options_view, 'third_party_auth_request', @handleThirdPartyAuthRequest

    setupEmailView : (options) ->
      email_view = new Signin.ViaEmail
        model: options.user
        fixed: options.fixed
      
      @listenTo email_view, 'passwordReminderRequested', @handlePasswordReminderRequested      
      @listenTo email_view, 'signinCompleted', (data) => @handleSigninCompleted(data, email_view)

      email_view

    handleThirdPartyAuthRequest : (provider) ->
      App.request 'third_party_auth:new',
        provider : provider
        callback : (user_data) ->
          App.request "user:signin", user_data

    handlePasswordReminderRequested : (email) ->
      $.post Routes.user_password_path(), {user : {email: email}}, (data) =>
        @layout.emailAuthRegion.currentView.respondToPasswordReminderRequest data.result == 'success'

    handleSigninCompleted : (data, view) =>
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
        App.request 'user:fixed'
      else
        App.request 'user:current'

    getSigninLayout : ->
      new Signin.Layout
        model: @getUser()


  class Signin.PasswordResetController extends Signin.Controller
    initialize : ->
      super

      @listenTo @layout, 'before:close', ->
        App.request 'auth:password_reset:handled' 

    setupLayout : (layout) ->
      @listenTo layout, 'reset:complete', (data) => @handleSigninCompleted(data, layout)

    getSigninLayout : ->
      new Signin.PasswordResetView
        model: @getUser()



