@ConsiderIt.module "Shared", (Shared, App, Backbone, Marionette, $, _) ->
  class Shared.SharedController extends App.Controllers.Base
    initialize : ->
      view = new Shared.ProfileView
        el : @region.el

