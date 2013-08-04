class ConsiderIt.UserManagerView extends Backbone.View

  initialize : (options) -> 

  render : -> 
    if ConsiderIt.password_reset_token?
      @handle_password_reset()

    this

  events : 
    'click .m-user-accounts-switch-method' : 'switch_method'

  switch_method : ->
    if @registrationview && @registrationview.$el.is(':visible')
      @registrationview.cancel()
      @handle_user_signin()
    else if @signinview && @signinview.$el.is(':visible')
      @signinview.cancel()
      @handle_user_registration()
    else
      throw 'Bad application state'


  # handle_third_party_callback : (user_data) ->
  #   if @registrationview && @registrationview.$el.is(':visible')
  #     @registrationview.handle_third_party_callback(user_data)
      
  #   else if @signinview && @signinview.$el.is(':visible')
  #     @signinview.finish(user_data)
  #   else
  #     throw 'Bad application state'

  # Handles the edge case where the user tries to "sign in" with a third party when 
  # they really should have tried to "create an account"
  # quick_register : () ->
  #   @handle_user_registration()
  #   @registrationview.second_phase()

  handle_password_reset : ->
    @auth_overlay = @add_auth_overlay()

    @signinview = new ConsiderIt.PasswordResetView
      model : ConsiderIt.current_user
      el : @auth_overlay
      parent : this

    @signinview.render()
    @signinview.$el.bind 'destroyed', () => @post_signin()

    @center_overlay()

    @signinview


