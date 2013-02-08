class ConsiderIt.UserManagerView extends Backbone.View


  @logged_in_template : _.template( $("#tpl_logged_in").html() )
  @logged_out_template : _.template( $("#tpl_logged_out").html() )

  initialize : (options) -> 
    @$header_el = @$el.find('#nav-user')
    #@model.on('change:id', @render)

  render : () -> 
    if @model.id?
      @$header_el.html(
        ConsiderIt.UserManagerView.logged_in_template($.extend({}, @model.attributes, {
        }))
      )
    else
      @$header_el.html(
        ConsiderIt.UserManagerView.logged_out_template($.extend({}, @model.attributes, {
        }))
      )

    this

  events : 
    'click a.logout' : 'handle_user_logout'
    'click a.signin_link' : 'handle_user_signin'
    'click a.signup_link' : 'handle_user_registration'
    'mouseenter #nav-user .triangle' : 'nav_entered' 
    'mouseleave #nav-user .triangle' : 'nav_exited' 

  nav_entered : (ev) -> 
    $(ev.currentTarget).find('.hide')
      .stop(true,false)
      .css('height', '')
      .slideDown();

  nav_exited : (ev) ->
    $(ev.currentTarget).find('.hide')
      .stop(true,false)
      .slideUp();

  handle_user_logout : (ev) ->
    $.get Routes.destroy_user_session_path(), (data) =>
      ConsiderIt.utils.update_CSRF(data.new_csrf)
      @model = ConsiderIt.current_user = new ConsiderIt.User
      @render()
      ConsiderIt.router.navigate(Routes.root_path(), {trigger: true})
      ConsiderIt.app.trigger('user:signout')      

  add_registration_overlay : () ->
    me = ConsiderIt.app.usermanagerview
    $overlay = $('<div id="registration_overlay">')
    me.$header_el.prepend($overlay)
    $overlay

  center_overlay : () ->
    $overlay = $('#registration_overlay')
    $overlay.offset 
      top: $('body').scrollTop() + window.innerHeight / 2 - $overlay.outerHeight() / 2     
      left: window.innerWidth / 2 - $overlay.outerWidth() / 2


  post_signin : () ->
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
    me.registrationview.$el.bind 'destroyed', () =>
      @post_signin()

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
    me.signinview.$el.bind 'destroyed', () => 
      @post_signin()

    me.center_overlay()

    me.signinview




  handle_third_party_callback : (user_data) ->
    if @registrationview && @registrationview.$el.is(':visible')
      @registrationview.finish_first_phase(user_data.user)
    else if @signinview && @signinview.$el.is(':visible')
      @signinview.finish(user_data.user)
    else
      throw 'Bad application state'

  # Handles the edge case where the user tries to "sign in" with a third party when 
  # they really should have tried to "create an account"
  quick_register : () ->
    @handle_user_registration()
    @registrationview.second_phase()
