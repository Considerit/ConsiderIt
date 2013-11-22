@ConsiderIt.module "HeaderApp.Show", (Show, App, Backbone, Marionette, $, _) ->
  
  class Show.HeaderShowController extends App.Controllers.Base
    
    initialize: ->
      layout = @getLayout()
      @listenTo layout, 'show', =>

        # setup appropriate header navigation after route has finished
        App.vent.on 'route:started', (crumbs) =>
          if crumbs.length < 2
            layout.navRegion.reset()
            logo = @getLogo()
            layout.logoRegion.show logo

          else
            nav = @getNav crumbs
            @listenTo nav, 'show', => @setupNav()
            layout.navRegion.show nav
            layout.logoRegion.reset()

      @show layout
      @layout = layout

    setupNav : ->

    getNav : (crumbs) ->
      new Show.NavView
        crumbs : crumbs

    getLogo : ->
      new Show.LogoView

    getLayout: ->
      new Show.Layout