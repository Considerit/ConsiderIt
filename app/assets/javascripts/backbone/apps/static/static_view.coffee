@ConsiderIt.module "Static", (Static, App, Backbone, Marionette, $, _) ->

  class Static.StaticView extends App.Views.ItemView
    className : 'static-page'
    getTemplate : ->
      "#tpl_static_#{@options.page}"