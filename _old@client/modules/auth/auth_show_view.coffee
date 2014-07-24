# @ConsiderIt.module "Auth.Show", (Show, App, Backbone, Marionette, $, _) ->

#   class Show.LoggedIn extends App.Views.ItemView
#     template: "#tpl_logged_in"

#     serializeData : ->
#       tenant = App.request 'tenant'
#       current_user = App.request 'user:current'
#       _.extend {}, @model.attributes, @model.permissions(),
#         avatar : App.request('user:current:avatar')
#         can_moderate : App.request('auth:can_moderate')
#         can_assess : App.request('auth:can_assess')
#         current_user : current_user

#     events:
#       'click [action="logout"]' : 'signoutRequested'
#       'mouseenter .user-options' : 'nav_entered' 
#       'mouseleave .user-options' : 'nav_exited' 
#       'click .user-options-dashboard_link' : 'access_dashboard'

#     signoutRequested : (ev) ->
#       @trigger 'signout:requested'

#     access_dashboard : (ev) -> 
#       $(ev.currentTarget)
#         .fadeIn(100).fadeOut(100).fadeIn(100).fadeOut(100).fadeIn(100)
#         .delay 100, => @nav_exited()

#     nav_entered : (ev) -> 
#       @$el.find('.user-options-menu-wrap')
#         .stop(true,false)
#         .css('height', '')
#         .slideDown();

#     nav_exited : () ->
#       @$el.find('.user-options-menu-wrap')
#         .stop(true,false)
#         .slideUp()


#   class Show.LoggedOut extends App.Views.ItemView
#     template: "#tpl_logged_out"

#     serializeData : ->
#       model_data = if @model then @model.attributes else {}
#       _.extend {}, model_data