@ConsiderIt.module "Franklin.Root", (Root, App, Backbone, Marionette, $, _) ->

  class Root.RootController extends App.Controllers.Base

    initialize : (options = {}) ->
      layout = @getLayout()

      @listenTo layout, 'show', =>
        header = @getHeader()
        @listenTo App.vent, 'user:signin user:signout', =>
          layout.headerRegion.show header

        layout.headerRegion.show header
        proposals_controller = @getProposalsController layout

      @region.show layout

    getLayout : ->
      new Root.Layout

    getHeader : ->
      new Root.HeaderView
        model : App.request 'tenant'

    getProposalsController : (layout) ->
      c = new App.Franklin.Proposals.ProposalsRegionController
          region: layout.proposalsRegion
          parent_controller : @
          last_proposal_id : @options.last_proposal_id
      c
