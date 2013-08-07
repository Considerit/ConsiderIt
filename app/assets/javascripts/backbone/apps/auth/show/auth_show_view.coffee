@ConsiderIt.module "Auth.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.LoggedIn extends App.Views.ItemView
    template: "#tpl_logged_in"

    serializeData : ->
      _.extend {}, @model.attributes, @model.permissions()

    events:
      'click .m-user-options-logout' : 'signoutRequested'
      'mouseenter .m-user-options' : 'nav_entered' 
      'mouseleave .m-user-options' : 'nav_exited' 
      'click .m-user-options-dashboard_link' : 'access_dashboard'

    signoutRequested : (ev) ->
      @trigger 'signout:requested'

    access_dashboard : (ev) -> 
      $(ev.currentTarget)
        .fadeIn(100).fadeOut(100).fadeIn(100).fadeOut(100).fadeIn(100)
        .delay 100, => @nav_exited()

    nav_entered : (ev) -> 
      @$el.find('.m-user-options-menu-wrap')
        .stop(true,false)
        .css('height', '')
        .slideDown();

    nav_exited : () ->
      @$el.find('.m-user-options-menu-wrap')
        .stop(true,false)
        .slideUp()


  class Show.LoggedOut extends App.Views.ItemView
    template: "#tpl_logged_out"

    events : 
      'click [data-target="login"]' : 'user_signin_clicked'
      'click [data-target="create_account"]' : 'user_registration_clicked'

    user_signin_clicked : ->
      @trigger 'signin:requested'

    user_registration_clicked : ->
      @trigger 'registration:requested'

    serializeData : ->

      _.extend {}, @model.attributes, 
        show_signin : @options.show_signin
        show_register : @options.show_register
