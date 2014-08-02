@ConsiderIt.module "Franklin.Homepage", (Homepage, App, Backbone, Marionette, $, _) ->

  class Homepage.HomepageController extends App.Controllers.Base

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
      new Homepage.HomepageLayout

    getHeader : ->
      new Homepage.HomepageHeadingView
        model : App.request 'tenant'

    getProposalsController : (layout) ->
      c = new App.Franklin.Proposals.ProposalsRegionController
          region: layout.proposalsRegion
          parent_controller : @
          last_proposal_id : @options.last_proposal_id
      c
