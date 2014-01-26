@ConsiderIt.module "FooterApp.Show", (Show, App, Backbone, Marionette, $, _) ->
  
  class Show.Footer extends App.Views.ItemView
    template: "#tpl_footer"
    className : 'l-footer-wrap'