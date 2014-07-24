# @ConsiderIt.module "Auth.Show", (Show, App, Backbone, Marionette, $, _) ->
  
#   class Show.AuthShowController extends App.Controllers.Base
    
#     initialize: ->
#       user = App.request 'user:current'

#       if App.request 'user:is_client_logged_in?'

#         @view = @getLoggedInView user

#         @view.on 'signout:requested', =>
#           App.vent.trigger 'signout:requested'          

#         App.vent.on 'user:updated', =>
#           @view.render()

#       else
#         @view = @getLoggedOutView user

#       @show @view

#       # if ConsiderIt.password_reset_token?
#       #   @handle_password_reset()

#     getLoggedInView : (user) -> 
#       new Show.LoggedIn 
#         model: user

#     getLoggedOutView : (user) ->
#       fixed = if App.request('user:fixed:exists') then App.request('user:fixed') else null      
#       new Show.LoggedOut
#         model: user