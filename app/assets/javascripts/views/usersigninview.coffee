class ConsiderIt.SignInView extends Backbone.View

class ConsiderIt.PasswordResetView extends ConsiderIt.SignInView


  initialize : (options) -> 
    @user_reset_password_template = _.template( $("#tpl_user_reset_password").html() )


  render : () -> 

    @$el.html(
      @user_reset_password_template($.extend({}, @model.attributes, {
        password_reset_token : ConsiderIt.password_reset_token
      }))
    )

    @$el.find('input[type="file"]').customFileInput()
    @$el.find('form').h5Validate({errorClass : 'error'})
    if !Modernizr.input.placeholder
      @$el.find('[placeholder]').simplePlaceholder() 
    else
      @$el.find('#user_password').focus()

    this

  events : 
    'ajax:complete form' : 'sign_in'
    'click .m-user-accounts-cancel' : 'cancel'    

  sign_in : ->
    ConsiderIt.password_reset_token = null
    super

  cancel : ->
    ConsiderIt.password_reset_token = null
    super