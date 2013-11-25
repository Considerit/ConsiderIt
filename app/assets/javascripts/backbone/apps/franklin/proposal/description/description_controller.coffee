@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->
  
  class Proposal.DescriptionController extends App.Controllers.StatefulController

    state_map : ->
      map = {}
      map[Proposal.State.collapsed] = Proposal.DescriptionState.collapsed
      map[Proposal.State.expanded.crafting] = Proposal.DescriptionState.expandedSeparated
      map[Proposal.State.expanded.results] = Proposal.DescriptionState.expandedTogether
      map


    initialize : (options = {}) ->
      super options

      @model = options.model
      @layout = @getLayout()

      @setupLayout @layout

      @region.open = (view) => @transition @region, view # this will set how this region handles the transitions between views
      @region.show @layout

    processStateChange : ->
      if @prior_state != @state
        @layout = @resetLayout @layout

    transition : (region, view) ->

      already_showing_details = region.$el.find('.m-proposal-details').length > 0

      if @state != Proposal.DescriptionState.collapsed && @prior_state == Proposal.DescriptionState.collapsed && !already_showing_details
        
        view.ui.details.hide()
        region.$el.empty().append view.el
        view.ui.details.slideDown 500
        #view.ui.details.show()
      else# if @state == Proposal.DescriptionState.collapsed || @prior_state == null
        region.$el.empty().append view.el

    setupLayout : (layout) ->

      @listenTo layout, 'show', ->
        @listenTo layout, 'proposal:clicked', =>
          App.navigate Routes.new_position_proposal_path( @model.long_id ), {trigger: true}

        if App.request "auth:can_edit_proposal", @model
          @admin_controller = @getAdminController layout.adminRegion
          @setupAdminController @admin_controller

    setupAdminController : (controller) ->
      @listenTo controller, 'proposal:published', =>
        @trigger 'proposal:published'

      @listenTo controller, 'proposal:setting_changed', =>
        @trigger 'proposal:setting_changed'

    getAdminController : (region) ->
      new Proposal.AdminController
        model : @model
        region : region
        parent_state : @state
        parent_controller : @

    getLayout : ->
      new Proposal.ProposalDescriptionView
        model : @model
        state : @state

