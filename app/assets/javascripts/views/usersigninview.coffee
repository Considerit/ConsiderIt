class ConsiderIt.SignInView extends Backbone.View

  @signin_template : _.template( $("#tpl_user_signin").html() )

  initialize : (options) -> 
    @parent = options.parent

  render : () -> 
    @$el.html(
      ConsiderIt.SignInView.signin_template($.extend({}, @model.attributes, {

      }))
    )
    @$el.find('input[type="file"]').customFileInput()
    @$el.find('form').h5Validate({errorClass : 'error'})

    this

  events : 
    'ajax:complete form' : 'sign_in'
    'click .cancel' : 'cancel'
    'click a.forget_password_prompt' : 'show_send_password_prompt'
    'click button.send_reminder' : 'handle_forgetten_password'

  show_send_password_prompt : (ev) =>
    @$el.find('.send_reminder').show()    

  handle_forgetten_password : (ev) =>
    $.post Routes.user_password_path(), @user_attributes(), (data) =>
      note = "<div class='note'>Reminder has been sent.</div>"
      @$el.prepend(note)

  finish : (user_data) ->
    ConsiderIt.update_current_user(user_data)
    @remove()

    if !ConsiderIt.current_user.get('registration_complete')
      @parent.quick_register()

  sign_in : (ev, response, options) ->
    data = $.parseJSON(response.responseText)
    user = $.parseJSON(data.user)
    if data.result == 'successful'
      @finish(user.user)
    else if data.result == 'failure' && data.reason == 'wrong password'
      # TODO: help users if they previously signed in via third party
      note = "<div class='note'>Incorrect password.</div>"
      @$el.prepend(note)
    else if data.result == 'failure' && data.reason == 'no user'
      note = "<div class='note'>There is no user with that email address.</div>"
      @$el.prepend(note)
    else 
      throw 'Bad application state'

  cancel : (ev) ->
    @remove()