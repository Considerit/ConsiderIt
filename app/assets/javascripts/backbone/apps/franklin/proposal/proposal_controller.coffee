@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->
  
  Proposal.State =
    collapsed : 0
    expanded : 
      crafting : 1
      results : 4

  Proposal.ReasonsState =
    collapsed : 'collapsed'
    separated : 'separated'
    together : 'together'

  Proposal.DescriptionState = 
    collapsed : 'collapsed'
    expanded : 'expanded'
      
  #TODO: handle declarative Proposal states, and manage transitions

  class Proposal.ProposalController extends App.Controllers.Base
    exploded : false
    state : null

    initialize : (options = {}) ->
      _.defaults options, 
        proposal_state : Proposal.State.expanded.crafting

      @model = options.model
      @layout = options.view || @getLayout()

      @setupLayout @layout
      App.reqres.setHandler "proposal_controller:#{@model.id}", => @

      @setState @options.proposal_state
      @region.show @layout if !options.view #don't do redundant shows
      options.view = null

    setState : (state) ->
      return if state == @state
      @state = state
      @layout.setDataState @state if @layout
      @trigger 'state:changed', @state

    changeState : (state) ->
      prior_state = @state
      @setState state
      @showFinished prior_state

    showFinished : (prior_state = null) ->
      if prior_state && prior_state != Proposal.State.collapsed
        if @state == Proposal.State.collapsed
          @layout.$el.moveToTop 50, true
        else
          @aggregate_controller.layout.$el.moveToTop 50, true

      else
        $(document).scrollTop(0)


      if @state == Proposal.State.expanded.results
        @layout.explodeParticipants prior_state != null

      else if @exploded
        @layout.implodeParticipants()
        @exploded = false

    setupLayout : (layout) ->
      @listenTo layout, 'show', =>

        participants_view = @getParticipantsView()
        layout.participantsRegion.show participants_view

        @description_controller = @getDescriptionController layout.descriptionRegion
        @aggregate_controller = @getAggregateController layout.aggregateRegion
        @reasons_controller = @getReasonsController layout.reasonsRegion

        @setupDescriptionController @description_controller
        @setupAggregateController @aggregate_controller
        @setupReasonsController @reasons_controller

        @setupHistogramReasonsBridge @reasons_controller, @aggregate_controller

        @listenTo layout, 'explosion:complete', => @exploded = true

        @showFinished()



    setupDescriptionController : (controller) ->

    setupAggregateController : (controller) ->

    setupReasonsController : (controller) ->


    setupHistogramReasonsBridge : (reasons_controller, aggregate_controller) =>

      @listenTo reasons_controller, 'point:highlight_includers', (includers) =>
        if @state == Proposal.State.expanded.results && @exploded
          @trigger 'point:mouseover', includers

      @listenTo reasons_controller, 'point:unhighlight_includers', (includers) =>
        if @state == Proposal.State.expanded.results && @exploded
          @trigger 'point:mouseout', includers

      @listenTo aggregate_controller, 'histogram:segment_results', (segment) =>
        if @state == Proposal.State.expanded.results && @exploded
          reasons_controller.segmentPeerPoints segment

    getDescriptionController : (region) ->
      new Proposal.DescriptionController
        model : @model
        region : region
        parent_state : @state
        parent_controller : @

    getAggregateController : (region) ->
      new Proposal.AggregateController
        model : @model
        region : region
        parent_state : @state
        parent_controller : @

    getReasonsController : (region) ->
      new Proposal.ReasonsController
        model : @model
        region : region
        parent_state : @state
        parent_controller : @

    getParticipantsView : ->
      new Proposal.ParticipantsView
        model : @model

    getLayout : ->
      new Proposal.ProposalLayout
        model : @model
        state : @state
