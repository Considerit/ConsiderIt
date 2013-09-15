@ConsiderIt.module "Static", (Static, App, Backbone, Marionette, $, _) ->

  class Static.StaticController extends App.Controllers.Base
    initialize : ->
      layout = @getLayout @options.page
      @show layout

    getLayout : (page) ->
      new Static.StaticView 
        page : page