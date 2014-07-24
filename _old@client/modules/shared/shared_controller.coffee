@ConsiderIt.module "Shared", (Shared, App, Backbone, Marionette, $, _) ->
  class Shared.SharedController extends App.Controllers.Base
    initialize : ->
      view = new Shared.ProfileView
        el : @region.el

      loginview = new Shared.AuthView
        el : @region.el

  App.reqres.setHandler 'shared:actions', ->
    ['user_profile_page', 'user_opinion', 'create_account', 'login']
