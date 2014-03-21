@ConsiderIt.module "Notifications", (Notifications, App, Backbone, Marionette, $, _) ->
  App.commands.setHandler "notify:success", (message, options = {}) ->
    toastr.success message, null, _.defaults options, 
      positionClass : 'toast-bottom-left'
      showDuration: 100
      hideDuration: 600
      timeOut : 2000    


  App.commands.setHandler "notify:failure", (message, options = {}) ->
    toastr.error message, null, _.defaults options, 
      positionClass : 'toast-bottom-full-width'
      showDuration: 100
      hideDuration: 600
      timeOut : 4000
