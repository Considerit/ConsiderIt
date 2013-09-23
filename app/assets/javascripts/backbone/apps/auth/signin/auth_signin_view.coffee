@ConsiderIt.module "Auth.Signin", (Signin, App, Backbone, Marionette, $, _) ->

  class Signin.Layout extends App.Views.Layout
    template: "#tpl_user_signin"
    regions:
      emailAuthRegion : '.m-user-accounts-email-auth-region'
      authOptionsRegion : '.m-user-accounts-auth-options-region'

    dialog:
      title : 'Sign in'

  class Signin.FixedLayout extends Signin.Layout

    dialog: -> 
      title : "Welcome back, #{model.get('email')}! Please sign in."

    onRender: ->

  class Signin.AuthOptions extends App.Views.ItemView
    template: "#tpl_auth_options"

    serializeData : -> 
      providers : @options.providers
      switch_label : 'New here?'
      switch_prompt : 'Create Account'
      fixed : @options.fixed
      
    events:
      'click [data-target="third_party_auth"]' : 'thirdPartyAuthRequest'
      'click [data-provider="email"]' : 'emailAuthRequest'
      'click .m-user-accounts-switch-method' : 'switchMethod'

    switchMethod : ->
      @trigger 'switch_method_requested'

    thirdPartyAuthRequest : (ev) ->
      provider = $(ev.target).data('provider')
      @trigger 'third_party_auth_request', provider

    emailAuthRequest : (ev) ->
      @trigger 'email_auth_request'


  class Signin.ViaEmail extends App.Views.ItemView
    template: "#tpl_signin_via_email"

    serializeData : -> 
      {fixed : @options.fixed}

    onShow : ->
      @$el.find('input[type="file"]').customFileInput()
      @$el.h5Validate({errorClass : 'error'})
      if !Modernizr.input.placeholder
        @$el.find('[placeholder]').simplePlaceholder() 

      if !@options.fixed
        @$el.find('#user_email').focus() 

    respondToPasswordReminderRequest : (success) ->
      if success
        toastr.success 'Reminder has been sent.'
      else
        toastr.error 'We couldn\'t find an account matching that email.'

    signinFailed : (reason) ->
      if reason == 'wrong password'
        # TODO: help users if they previously signed in via third party
        toastr.error 'Incorrect password'
      else if reason == 'no user'
        toastr.error 'There is no user with that email address'
      else if reason == 'password token expired'
        toastr.error 'That link has expired, you need to request a new password reminder'

    events : 
      'click a.forget_password_prompt' : 'passwordReminderRequested'
      'ajax:complete form' : 'signinCompleted'

    passwordReminderRequested : (ev) ->
      @trigger 'passwordReminderRequested', @$el.find('#user_email').val()

    signinCompleted : (ev, response, options) ->
      data = $.parseJSON(response.responseText)
      @trigger 'signinCompleted', data



  class Signin.PasswordResetView extends App.Views.ItemView
    template: "#tpl_user_reset_password"

    dialog:
      title : 'Change your password'

    serializeView : ->
      _.extend {}, @model.attributes, 
        password_reset_token : App.request "auth:reset_password"

    onShow : ->
      @$el.find('input[type="file"]').customFileInput()
      @$el.find('form').h5Validate({errorClass : 'error'})

      if !Modernizr.input.placeholder
        @$el.find('[placeholder]').simplePlaceholder() 
      else
        @$el.find('#user_password').focus()
      
    events : 
      'ajax:complete form' : 'signinCompleted'
