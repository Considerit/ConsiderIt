@ConsiderIt.module "HeaderApp.Show", (Show, App, Backbone, Marionette, $, _) ->
  
  class Show.HeaderShowController extends App.Controllers.Base
    
    initialize: ->
      layout = @getLayout()
      @listenTo layout, 'show', =>

        # setup appropriate header navigation after route has finished
        @listenTo Backbone.history, 'route', (route, name, args) => 
          if name == 'Root'
            layout.navRegion.reset()
            logo = @getLogo()
            layout.logoRegion.show logo

          else
            nav = @getNav() #crumbs
            @listenTo nav, 'show', => @setupNav()
            layout.navRegion.show nav
            layout.logoRegion.reset()

      @show layout
      @layout = layout

    setupNav : ->

    getNav : ->
      new Show.NavView
        #crumbs : crumbs

    getLogo : ->
      new Show.LogoView

    getLayout: ->
      new Show.Layout