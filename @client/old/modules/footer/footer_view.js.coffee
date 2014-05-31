@ConsiderIt.module "Footer", (Footer, App, Backbone, Marionette, $, _) ->
  
  class Footer.FooterView extends App.Views.ItemView
    template: "#tpl_footer"
    className : 'l_footer_wrap'