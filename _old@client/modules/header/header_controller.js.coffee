@ConsiderIt.module "Header", (Header, App, Backbone, Marionette, $, _) ->
  
  class Header.HeaderController extends App.Controllers.Base
    
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
      new Header.NavView
        #crumbs : crumbs

    getLogo : ->
      new Header.LogoView

    getLayout: ->
      new Header.Layout