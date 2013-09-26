@ConsiderIt.module "Shared", (Shared, App, Backbone, Marionette, $, _) ->
  class Shared.UserTooltipController extends App.Controllers.Base
    initialize : ->
      view = new Shared.ProfileView
        el : @region.el

      loginview = new Shared.AuthView
        el : @region.el
