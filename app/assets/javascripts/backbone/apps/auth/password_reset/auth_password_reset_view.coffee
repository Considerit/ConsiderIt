@ConsiderIt.module "Auth.PasswordReset", (PasswordReset, App, Backbone, Marionette, $, _) ->

  class PasswordReset.View extends App.Views.ItemView
    template: "#tpl_user_reset_password"

    dialog:
      title : 'Change your password'

    serializeView : ->
      _.extend {}, @model.attributes, 
        password_reset_token : App.request "user:reset_password"

    onShow : ->
      @$el.find('input[type="file"]').customFileInput()
      @$el.find('form').h5Validate({errorClass : 'error'})

      if !Modernizr.input.placeholder
        @$el.find('[placeholder]').simplePlaceholder() 
      else
        @$el.find('#user_password').focus()
      
    events : 
      'ajax:complete form' : 'signinCompleted'

