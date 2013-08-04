@ConsiderIt.module "Auth.PasswordReset", (PasswordReset, App, Backbone, Marionette, $, _) ->

  class PasswordReset.Controller extends App.Auth.Signin.Controller
    initialize : ->
      super

      @listenTo @layout, 'before:close', ->
        App.request 'user:password_reset:handled' 

    setupLayout : (layout) ->
      @listenTo layout, 'signinCompleted', @handleSigninCompleted

    setupEmailView : (options) ->
      email_view = new Signin.ViaEmail
        model: options.user
        fixed: options.fixed
      
      @listenTo email_view, 'passwordReminderRequested', @handlePasswordReminderRequested      
      @listenTo email_view, 'signinCompleted', @handleSigninCompleted

      email_view

    getSigninLayout : ->
      new PasswordReset.View
        model: @getUser()


