@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->
  
  Proposal.State =
    Summary : 'summary'
    Crafting : 'crafting'
    Results : 'results'

  class Proposal.ProposalController extends App.Controllers.Base
    exploded : false # has the participants group yet been exploded into the histogram
    state : null #TODO: extend StatefulController to accommodate role of ProposalController

    transition_speed : -> 
      $transition_speed = if Modernizr.csstransitions then 1000 else 0
      $transition_speed

    initialize : (options = {}) ->
      _.defaults options, 
        proposal_state : Proposal.State.Crafting

      @model = options.model

      @layout = options.view || @getLayout()

      @setupLayout @layout

      @listenTo App.vent, 'user:signout', =>
        if !@model.openToPublic()
          @close()
          App.navigate Routes.root_path(), {trigger : true}
        else if @state != Proposal.State.Summary
          # This will clear out existing user opinions and create a new Opinion for the now anonymous user.
          # For some reason, if we do this in summary state, all proposals disappear so for now, just don't do it in that state.
          @layout.close()
          @description_controller.close()
          @histogram_controller.close()
          @reasons_controller.close()
          @toggle_controller.close()

          @layout = options.view || @getLayout()
          @setupLayout @layout
          @setState @state
          @region.show @layout

      App.reqres.setHandler "proposal_controller:#{@model.id}", => @

      @setState @options.proposal_state
      @region.show @layout if !options.view #don't do redundant shows
      options.view = null

    setState : (state) ->
      return if state == @state
      @state = state
      @layout.setDataState @state if @layout
      @trigger 'state:changed', @state

    showDescription : (new_state) ->
      @description_controller.changeState new_state

    changeState : (state) ->
      prior_state = @state
      @setState state
      @processStateChange prior_state

    processStateChange : (prior_state = null) ->
      
      if prior_state && prior_state != Proposal.State.Summary
        if @state == Proposal.State.Summary
          @layout.$el.moveToTop 50, true
        else
          @histogram_controller.layout.$el.ensureInView
            speed: @transition_speed()

      else
        $(document).scrollTop(0)

      if @state == Proposal.State.Results
        _.delay =>
          @layout.explodeParticipants prior_state != null && prior_state != Proposal.State.Crafting
        , @transition_speed()

      else if @exploded #&& @state == Proposal.State.Summary
        @layout.implodeParticipants()
        @exploded = false

    setupLayout : (layout) ->
      @listenTo layout, 'show', =>
        @description_controller = @getDescriptionController layout.descriptionRegion
        @histogram_controller = @getHistogramController layout.histogramRegion
        @reasons_controller = @getReasonsController layout.reasonsRegion
        @toggle_controller = @getStateToggleController layout.stateToggleRegion

        @setupDescriptionController @description_controller
        @setupAggregateController @histogram_controller
        @setupReasonsController @reasons_controller

        @setupHistogramReasonsBridge @reasons_controller, @histogram_controller

        @listenTo layout, 'explosion:complete', => @exploded = true

        @processStateChange()

    _update_attributes : ->
      @layout.$el.data @layout.attributes(false)
      @layout.$el.attr @layout.attributes()
      @trigger 'proposal:attributes:updated'
      #@region.show @layout

    setupDescriptionController : (controller) ->
      @listenTo controller, 'proposal:published', =>
        @_update_attributes()

      @listenTo controller, 'proposal:setting_changed', =>
        @_update_attributes()

    setupAggregateController : (controller) ->

    setupReasonsController : (controller) ->
      @listenTo @, 'proposal:attributes:updated', =>
        controller.layout.sizeToFit()

    setupHistogramReasonsBridge : (reasons_controller, histogram_controller) =>

      @listenTo reasons_controller, 'point:highlight_includers', (includers) =>
        if @state == Proposal.State.Results && @exploded
          @trigger 'point:mouseover', includers

      @listenTo reasons_controller, 'point:unhighlight_includers', (includers) =>
        if @state == Proposal.State.Results && @exploded
          @trigger 'point:mouseout', includers

      @listenTo histogram_controller, 'histogram:segment_results', (segment) =>
        if @state == Proposal.State.Results && @exploded
          reasons_controller.segmentCommunityPoints segment

      @listenTo reasons_controller, 'opinion_published', =>
        @_update_attributes()
        histogram_controller.createHistogram()

    getDescriptionController : (region) ->
      new Proposal.DescriptionController
        model : @model
        region : region
        parent_state : @state
        parent_controller : @

    getHistogramController : (region) ->
      new Proposal.HistogramController
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



    getStateToggleController : (region) ->
      new Proposal.ToggleProposalStateController
        model : @model
        region : region
        parent_state : @state
        parent_controller : @

    getLayout : ->
      new Proposal.ProposalLayout
        model : @model
        state : @state
