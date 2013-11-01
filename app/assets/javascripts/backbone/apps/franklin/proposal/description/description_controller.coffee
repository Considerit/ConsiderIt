@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->
  
  class Proposal.DescriptionController extends App.Controllers.StatefulController

    state_map : ->
      map = {}
      map[Proposal.State.collapsed] = Proposal.ReasonsState.collapsed
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
      if @state != Proposal.DescriptionState.collapsed && @prior_state == Proposal.DescriptionState.collapsed
        region.$el.empty().append view.el
        view.ui.details.hide()
        region.$el.empty().append view.el
        view.ui.details.slideDown 400
      else# if @state == Proposal.DescriptionState.collapsed || @prior_state == null
        region.$el.empty().append view.el

    setupLayout : (layout) ->

      @listenTo layout, 'show', ->
        @listenTo layout, 'proposal:clicked', =>
          App.navigate Routes.new_position_proposal_path( @model.long_id ), {trigger: true}

        @listenTo layout, 'show_results', =>
          if @state != Proposal.ReasonsState.together
            App.navigate Routes.proposal_path(@model.long_id), {trigger: true}

            if @prior_state == Proposal.ReasonsState.separated
              layout.moveToResults()


    getLayout : ->


      if @state == Proposal.DescriptionState.collapsed
        new Proposal.SummaryProposalDescription
          model : @model
          state : @state
      else
        new Proposal.ProposalDescriptionView
          model : @model
          state : @state

