@ConsiderIt.module "Franklin.Root", (Root, App, Backbone, Marionette, $, _) ->

  class Root.Controller extends App.Controllers.Base

    initialize : (options = {}) ->
      layout = @getLayout()

      @listenTo layout, 'show', =>
        header = @getHeader()        
        layout.headerRegion.show header
        proposals_controller = @getProposalsController layout

      @region.show layout

    getLayout : ->
      new Root.Layout

    getHeader : ->
      new Root.HeaderView

    getProposalsController : (layout) ->
      new App.Franklin.Proposals.RegionController
          region: layout.proposalsRegion
