class ConsiderIt.UserManagerView extends Backbone.View


  @logged_in_template : _.template( $("#tpl_logged_in").html() )
  @logged_out_template : _.template( $("#tpl_logged_out").html() )

  initialize : (options) -> 
    @$header_el = @$el.find('#m-user-nav')
    #@model.on('change:id', @render)

    @on 'user:signin', -> 
      $('#registration_overlay').remove()

    @listenTo ConsiderIt.app, 'user:updated', ->
      @render() #this should only be updated the user-nav

  render : -> 
    if @model.id?
      @$header_el.html(
        ConsiderIt.UserManagerView.logged_in_template($.extend({}, @model.attributes, {
          is_admin : ConsiderIt.roles.is_admin
          is_moderator : ConsiderIt.roles.is_moderator
          is_analyst : ConsiderIt.roles.is_analyst
          is_evaluator : ConsiderIt.roles.is_evaluator
          is_manager : ConsiderIt.roles.is_manager
        }))
      )
    else
      @$header_el.html(
        ConsiderIt.UserManagerView.logged_out_template($.extend({}, @model.attributes, {
        })) 
      )

    if ConsiderIt.password_reset_token?
      @handle_password_reset()
    #else if ConsiderIt.limited_user_email?
    #  if ConsiderIt.limited_user?
    #    @handle_user_signin()
    #  else
    #    @handle_user_registration()


    this

  remove : ->
    super
    $('#registration_overlay').remove()



  events : 
    'click .m-login-signin' : 'handle_user_signin'
    'click .m-login-signup' : 'handle_user_registration'
    'click .m-user-accounts-switch-method' : 'switch_method'
    'click .m-user-options-logout' : 'handle_user_logout'
    'mouseenter .m-user-options' : 'nav_entered' 
    'mouseleave .m-user-options' : 'nav_exited' 
    'click .m-user-options-dashboard_link' : 'access_dashboard'

  access_dashboard : (ev) -> 
    $(ev.currentTarget)
      .fadeIn(100).fadeOut(100).fadeIn(100).fadeOut(100).fadeIn(100)
      .delay(100, => @nav_exited())

  nav_entered : (ev) -> 
    $(ev.currentTarget).find('.m-user-options-menu-wrap')
      .stop(true,false)
      .css('height', '')
      .slideDown();

  nav_exited : () ->
    @$header_el.find('.m-user-options-menu-wrap')
      .stop(true,false)
      .slideUp()

  handle_user_logout : (ev) ->
    $.get Routes.destroy_user_session_path(), (data) =>
      ConsiderIt.utils.update_CSRF(data.new_csrf)
      @model = ConsiderIt.clear_current_user()
      @render()
      #ConsiderIt.router.navigate(Routes.root_path(), {trigger: true})
      ConsiderIt.app.trigger('user:signout')      

  add_registration_overlay : () ->
    me = ConsiderIt.app.usermanagerview
    $overlay = $('<div class="l-overlay" id="registration_overlay">')
    $('#l-wrap').prepend($overlay)
    $overlay

  center_overlay : () ->
    $overlay = $('#registration_overlay')
    $overlay.offset 
      #top: $('body').scrollTop() + window.innerHeight / 2 - $overlay.outerHeight() / 2     
      top: $('body').scrollTop() + 50
      left: window.innerWidth / 2 - $overlay.outerWidth() / 2


  post_signin : () ->
    $('#registration_overlay').remove()

    if !ConsiderIt.current_user.isNew()
      @model = ConsiderIt.current_user
      @render()
      ConsiderIt.app.trigger('user:signin')

  handle_user_registration : (ev) ->
    me = ConsiderIt.app.usermanagerview

    me.registration_overlay = me.add_registration_overlay()

    me.registrationview = new ConsiderIt.RegistrationView
      model : ConsiderIt.current_user
      el : me.registration_overlay
      parent : me

    me.registrationview.render()
    me.registrationview.$el.bind 'destroyed', () => @post_signin()

    me.center_overlay()

    me.registrationview


  handle_user_signin : (ev) ->  
    me = ConsiderIt.app.usermanagerview

    me.registration_overlay = me.add_registration_overlay()

    me.signinview = new ConsiderIt.SignInView
      model : ConsiderIt.current_user
      el : me.registration_overlay
      parent : me

    me.signinview.render()
    me.signinview.$el.bind 'destroyed', () => @post_signin()

    me.center_overlay()

    me.signinview

  switch_method : ->
    if @registrationview && @registrationview.$el.is(':visible')
      @registrationview.cancel()
      @handle_user_signin()
    else if @signinview && @signinview.$el.is(':visible')
      @signinview.cancel()
      @handle_user_registration()
    else
      throw 'Bad application state'


  handle_third_party_callback : (user_data) ->
    if @registrationview && @registrationview.$el.is(':visible')
      @registrationview.handle_third_party_callback(user_data)
      
    else if @signinview && @signinview.$el.is(':visible')
      @signinview.finish(user_data)
    else
      throw 'Bad application state'

  # Handles the edge case where the user tries to "sign in" with a third party when 
  # they really should have tried to "create an account"
  quick_register : () ->
    @handle_user_registration()
    @registrationview.second_phase()

  handle_password_reset : ->
    @registration_overlay = @add_registration_overlay()

    @signinview = new ConsiderIt.PasswordResetView
      model : ConsiderIt.current_user
      el : @registration_overlay
      parent : this

    @signinview.render()
    @signinview.$el.bind 'destroyed', () => 
      @post_signin()

    @center_overlay()

    @signinview






