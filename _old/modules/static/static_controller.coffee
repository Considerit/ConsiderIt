@ConsiderIt.module "Static", (Static, App, Backbone, Marionette, $, _) ->

  class Static.StaticController extends App.Controllers.Base
    initialize : ->
      layout = @getLayout @options.page
      @listenTo layout, 'show', =>
        page_view = @getPage @options.page
        layout.mainRegion.show page_view

        sidebar_view = @getSidebar @options.page
        layout.sidebarRegion.show sidebar_view

      @show layout

    getLayout : (page) ->
      new Static.StaticLayout
        title : page

    getPage : (page) ->
      new Static.StaticView
        page : page

    getSidebar : (page) ->
      new Static.StaticSidebar
        page : page