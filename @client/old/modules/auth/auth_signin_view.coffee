@ConsiderIt.module "Auth.Signin", (Signin, App, Backbone, Marionette, $, _) ->

  class Signin.Layout extends App.Views.Layout
    template: "#tpl_user_signin"
    regions:
      emailAuthRegion : '.user-accounts-email-auth-region'
      authOptionsRegion : '.user-accounts-auth-options-region'

    dialog : 
      title : 'Hi! Please log in'

    attributes : -> 
      class : if @options.fixed then 'user_accounts_layout_fixed' else 'user_accounts_layout_not_fixed'

  class Signin.FixedLayout extends Signin.Layout

    dialog: -> 
      title : "Welcome back, #{@model.get('email')}! Please sign in."


  class Signin.AuthOptions extends App.Views.ItemView
    template: "#tpl_auth_options"

    serializeData : -> 
      providers : @options.providers
      fixed : @options.fixed
      
    events:
      'click [action="third_party_auth"]' : 'thirdPartyAuthRequest'

    thirdPartyAuthRequest : (ev) ->
      provider = $(ev.target).data('provider')
      @trigger 'third_party_auth_request', provider


  class Signin.ViaEmail extends App.Views.ItemView
    template: "#tpl_signin_via_email"

    serializeData : -> 
      params = 
        fixed : @options.fixed
        email : if @options.fixed then @model.get('email') else null
        app_title : App.request('tenant').get('app_title')
      params

    onShow : ->
      # @$el.find('input[type="file"]').customFileInput()
      @$el.h5Validate('form').h5Validate
        errorClass : 'error'
        keyup : true

      if !Modernizr.input.placeholder
        @$el.find('#user_email[placeholder]').simplePlaceholder() 


      selector = if @options.selected != 'has_pass' then '#password_has' else '#password_none'

      $password_input = @$el.find selector
      $password_input.trigger 'click'

      @toggleInput @options.selected != 'has_pass'

      if !@options.fixed
        @$el.find('#user_email').focus() 


    respondToPasswordReminderRequest : (success) ->
      if success
        App.execute 'notify:success', 'Reminder has been sent.'
      else
        App.execute 'notify:failure', 'We couldn\'t find an account matching that email.'

    signinFailed : (reason) ->
      if reason == 'wrong password'
        # TODO: help users if they previously signed in via third party
        App.execute 'notify:failure', 'Incorrect password'
      else if reason == 'no user'
        App.execute 'notify:failure', 'There is no user with that email address'
      else if reason == 'password token expired'
        App.execute 'notify:failure', 'That link has expired, you need to request a new password reminder'

    events : 
      'click a.forget_password_prompt' : 'passwordReminderRequested'
      'ajax:complete form' : 'signinCompleted'
      'change #password_has' : 'passwordHasChanged'
      'change #password_none' : 'passwordNoneChanged'
      'validated #user_email,#user_password' : 'checkIfSubmitEnabled'
      'click [action="create-account"]' : 'registerAccount'
      'click [action="login-submit"]' : 'submitLogin'

    submitLogin : (ev) ->
      $(ev.currentTarget).parents('form').submit()
      ev.stopPropagation()


    toggleInput : (currently_has_password) ->
      $password_area = @$el.find('#password_has').siblings('.user-account-password')
      $submit_button_login = @$el.find('[action="login-submit"]')
      $submit_button_register = @$el.find('[action="create-account"]')
      if !currently_has_password
        $password_area.css
          opacity : '.5'
          pointerEvents : 'none' 
        $password_area.find('input').prop 'disabled', 'disabled'
        $submit_button_login.hide()
        $submit_button_register.show()
      else
        $password_area.css
          opacity : ''
          pointerEvents : ''
        $password_area.find('input').removeProp('disabled').focus()
        $submit_button_login.show()
        $submit_button_register.hide()

      @checkIfSubmitEnabled()


    passwordNoneChanged : (ev) ->
      @toggleInput false

    passwordHasChanged : (ev) ->
      @toggleInput true

    checkIfSubmitEnabled : ->
      $email_field = @$el.find('#user_email')
      $password_field = @$el.find('#user_password')
      $submit_button_login = @$el.find('[action="login-submit"]')
      $submit_button_register = @$el.find('[action="create-account"]')
      is_new_user = @$el.find('#password_none:checked').length > 0 && !@options.fixed

      if is_new_user
        if $email_field.is '.ui-state-valid'
          $submit_button_register.removeAttr('disabled')
        else 
          $submit_button_register.attr 'disabled', 'true'
      else
        if $email_field.is('.ui-state-valid') && $password_field.is('.ui-state-valid')
          $submit_button_login.removeAttr('disabled')
        else 
          $submit_button_login.attr 'disabled', 'true'

    passwordReminderRequested : (ev) ->
      @trigger 'passwordReminderRequested', @$el.find('#user_email').val()

    signinCompleted : (ev, response, options) ->
      data = $.parseJSON(response.responseText)
      @trigger 'signinCompleted', data

    registerAccount : (ev) ->
      params = 
        email : @$el.find('#user_email').val()
      @trigger 'emailRegistrationRequested', params
      ev.stopPropagation()



  class Signin.PasswordResetView extends App.Views.ItemView
    template: "#tpl_user_reset_password"
    className: 'user-accounts-password-reset-form'
    dialog:
      title : 'Change your password'

    serializeData : ->
      token = App.request "auth:reset_password"

      _.extend {}, @model.attributes, 
        password_reset_token : token

    signinFailed : (reason) ->
      if reason == 'wrong password'
        # TODO: help users if they previously signed in via third party
        App.execute 'notify:failure', 'Incorrect password'
      else if reason == 'no user'
        App.execute 'notify:failure', 'There is no user with that email address'
      else if reason == 'password token expired'
        App.execute 'notify:failure', 'That link has expired, you need to request a new password reminder'


    onShow : ->
      # @$el.find('input[type="file"]').customFileInput()
      @$el.find('form').h5Validate
        errorClass : 'error'
        keyup : true

      if !Modernizr.input.placeholder
        @$el.find('[placeholder]').simplePlaceholder() 
      else
        @$el.find('#user_password').focus()
      
    events : 
      'ajax:complete form' : 'resetComplete'

    resetComplete : (ev, response, options) ->
      data = $.parseJSON(response.responseText)
      @trigger 'reset:complete', data
