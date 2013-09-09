@ConsiderIt.module "Franklin.Root", (Root, App, Backbone, Marionette, $, _) ->

  class Root.Layout extends App.Views.Layout
    template: "#tpl_homepage_layout"

    regions :
      headerRegion : '#m-homepage-header'
      proposalsRegion : '#m-homepage-proposals'


  class Root.HeaderView extends App.Views.ItemView
    template: '#tpl_homepage_heading'



    