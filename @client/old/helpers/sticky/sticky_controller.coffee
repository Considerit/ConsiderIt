@ConsiderIt.module "Helpers.Sticky", (Sticky, App, Backbone, Marionette, $, _) ->
  class Sticky.StickyController extends App.Controllers.Base

    initialize : (options={}) ->
      @contentView = options.view
      @layout = @getLayout()
      @setupLayout @layout

    setupLayout : (layout) ->
      @listenTo layout, "show", =>
        layout.contentRegion.show @contentView

        @listenTo @contentView, 'close', ->
          @close()

    close : ->
      @contentView.close() 
      super

    getLayout : ->
      new Sticky.StickyLayout


  App.reqres.setHandler "sticky_footer:new", (contentView, options = {}) ->
    options.class ?= ''

    @stickyController.close() if @stickyController

    @stickyController = new Sticky.StickyController
      view: contentView
      config: options
      region: App.stickyFooterRegion

    @stickyController.show @stickyController.layout
    @stickyController.layout
    

  App.reqres.setHandler "sticky_footer:close", (contentView, options = {}) ->
    if @stickyController
      @stickyController.contentView.$el.fadeOut 300, =>
        @stickyController.close()