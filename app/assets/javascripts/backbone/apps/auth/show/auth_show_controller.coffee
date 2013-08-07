@ConsiderIt.module "Auth.Show", (Show, App, Backbone, Marionette, $, _) ->
  
  class Show.Controller extends App.Controllers.Base
    
    initialize: ->
      user = App.request "user:current"
      if user.is_persisted()
        @view = @getLoggedInView user

        @view.on 'signout:requested', =>
          App.vent.trigger 'signout:requested'          

        App.vent.on 'user:updated', =>
          @view.render()

      else
        @view = @getLoggedOutView user

        @view.on 'signin:requested', =>
          App.vent.trigger 'signin:requested'

        @view.on 'registration:requested', => 
          App.vent.trigger 'registration:requested'

      @show @view

      # if ConsiderIt.password_reset_token?
      #   @handle_password_reset()

    getLoggedInView : (user) -> 
      new Show.LoggedIn 
        model: user

    getLoggedOutView : (user) ->
      fixed = if App.request('user:fixed:exists') then App.request('user:fixed') else null      
      new Show.LoggedOut
        model: user
        show_signin : !fixed || fixed.is_persisted()
        show_register : !fixed || !fixed.is_persisted()
