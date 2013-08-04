@ConsiderIt.module "HeaderApp.Show", (Show, App, Backbone, Marionette, $, _) ->
  
  class Show.Layout extends App.Views.Layout
    template: "#tpl_header"

    regions:
      userNavRegion: "#m-user-nav"