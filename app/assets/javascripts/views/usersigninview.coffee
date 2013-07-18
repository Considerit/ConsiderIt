class ConsiderIt.SignInView extends Backbone.View

  @signin_template : _.template( $("#tpl_user_signin").html() )

  initialize : (options) -> 
    @parent = options.parent

  render : () -> 
    if ConsiderIt.limited_user_email?

      @$el.html(
        _.template($("#tpl_limited_user_sign_in").html(), $.extend({}, ConsiderIt.limited_user.attributes, {
          auth_method : if ConsiderIt.limited_user? then ConsiderIt.limited_user.auth_method() else null
        }))
      )
      @$el.find('.m-user-accounts-complete').show()

    else
      @$el.html(
        ConsiderIt.SignInView.signin_template($.extend({}, @model.attributes, {}))
      )

    @$el.find('input[type="file"]').customFileInput()
    @$el.find('form').h5Validate({errorClass : 'error'})

    this

  events : 
    'ajax:complete form' : 'sign_in'
    'click [data-target="close_dialog"]' : 'cancel'    
    'click a.forget_password_prompt' : 'handle_forgetten_password'
    'click .m-user-accounts-login-option .email' : 'login_option_choosen'

  login_option_choosen : (ev) ->
    choice = $(ev.currentTarget).data('provider')

    @$el.find(".m-user-accounts-authorized-feedback").hide()
    @$el.find(".m-user-accounts-authorized-feedback[data-provider='#{choice}']").show()

    @$el.find('.m-user-accounts-choose-method').hide()
    @$el.find('.m-user-accounts-complete').show()

    if choice == 'email'
      @$el.find('#user_email').focus()

      if !Modernizr.input.placeholder
        @$el.find('[placeholder]').simplePlaceholder() 


  handle_forgetten_password : (ev) =>
    $.post Routes.user_password_path(), {user : {email: @$el.find('#user_email').val()}}, (data) =>

      if data.result == 'success'
        note = 'Reminder has been sent.'
      else
        note = 'We couldn\'t find an account matching that email.'

      @$el.find('.note').remove()
      @$el.prepend( "<div class='note'>#{note}</div>")

  finish : (user_data) ->
    ConsiderIt.update_current_user(user_data)
    @remove()

    if !ConsiderIt.current_user.get('registration_complete')
      @parent.quick_register()

  sign_in : (ev, response, options) ->
    data = $.parseJSON(response.responseText)
    if data.result == 'successful'
      data.user = data.user.user
      @finish(data)
    else if data.result == 'failure' && data.reason == 'wrong password'
      # TODO: help users if they previously signed in via third party
      note = "<div class='note'>Incorrect password.</div>"
      @$el.prepend(note)
    else if data.result == 'failure' && data.reason == 'no user'
      note = "<div class='note'>There is no user with that email address.</div>"
      @$el.prepend(note)
    else if data.result == 'failure' && data.reason == 'password token expired'
      note = "<div class='note'>That link has expired, you need to request a new password reminder.</div>"
      @$el.prepend(note)

    else 
      throw 'Bad application state'

  cancel : (ev) ->
    ConsiderIt.current_user.clear()
    @remove()





class ConsiderIt.PasswordResetView extends ConsiderIt.SignInView


  initialize : (options) -> 
    @user_reset_password_template = _.template( $("#tpl_user_reset_password").html() )

    @parent = options.parent

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