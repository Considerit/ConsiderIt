@ConsiderIt.module "Auth.Signin", (Signin, App, Backbone, Marionette, $, _) ->

  class Signin.Layout extends App.Views.Layout
    template: "#tpl_user_signin"
    regions:
      emailAuthRegion : '.m-user-accounts-email-auth-region'
      authOptionsRegion : '.m-user-accounts-auth-options-region'

    dialog : 
      title : 'Hi! Please log in'

    attributes : -> 
      class : if @options.fixed then 'm-user-accounts-layout-fixed' else 'm-user-accounts-layout-not-fixed'

  class Signin.FixedLayout extends Signin.Layout

    dialog: -> 
      title : "Welcome back, #{@model.get('email')}! Please sign in."


  class Signin.AuthOptions extends App.Views.ItemView
    template: "#tpl_auth_options"

    serializeData : -> 
      providers : @options.providers
      fixed : @options.fixed
      
    events:
      'click [data-target="third_party_auth"]' : 'thirdPartyAuthRequest'

    thirdPartyAuthRequest : (ev) ->
      provider = $(ev.target).data('provider')
      @trigger 'third_party_auth_request', provider


  class Signin.ViaEmail extends App.Views.ItemView
    template: "#tpl_signin_via_email"

    serializeData : -> 
      params = 
        fixed : @options.fixed
        email : if @options.fixed then @model.get('email') else null
        app_title : App.request('tenant:get').get('app_title')
      params

    onShow : ->
      # @$el.find('input[type="file"]').customFileInput()
      @$el.h5Validate('form').h5Validate
        errorClass : 'error'
        keyup : true

      if !Modernizr.input.placeholder
        @$el.find('[placeholder]').simplePlaceholder() 


      selector = if @options.selected == 'has_pass' then '#password_none' else '#password_has'
      $password_input = @$el.find selector
      $password_input.trigger 'click'

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
      'change #password_has' : 'passwordHasChanged'
      'change #password_none' : 'passwordNoneChanged'
      'validated #user_email,#user_password' : 'checkIfSubmitEnabled'
      'click .m-user-accounts-register-next' : 'registerAccount'

    setInput : (has_password) ->
      if has_password
        $now_checked = @$el.find('#password_has')
        #$not_checked = @$el.find('#password_none') 
      else
        $now_checked = @$el.find('#password_none') 
        #$not_checked = @$el.find('#password_has')

      $now_checked.trigger 'click'
      #$now_checked.attr 'checked', 'checked'
      #$not_checked.removeAttr 'checked'

      #@toggleInput has_password



    toggleInput : (has_password) ->
      $password_area = @$el.find('#password_has').siblings('.m-user-account-password')
      $submit_button_login = @$el.find('.m-user-accounts-login-submit')
      $submit_button_register = @$el.find('.m-user-accounts-register-next')
      if !has_password
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
      $submit_button_login = @$el.find('.m-user-accounts-login-submit')
      $submit_button_register = @$el.find('.m-user-accounts-register-next')
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
    className: 'm-user-accounts-password-reset-form'
    dialog:
      title : 'Change your password'

    serializeData : ->
      token = App.request "auth:reset_password"

      _.extend {}, @model.attributes, 
        password_reset_token : token

    signinFailed : (reason) ->
      if reason == 'wrong password'
        # TODO: help users if they previously signed in via third party
        toastr.error 'Incorrect password'
      else if reason == 'no user'
        toastr.error 'There is no user with that email address'
      else if reason == 'password token expired'
        toastr.error 'That link has expired, you need to request a new password reminder'


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
