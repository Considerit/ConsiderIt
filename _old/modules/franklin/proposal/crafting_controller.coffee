@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->

  class Proposal.CraftingController extends App.Controllers.StatefulController
    transitions_enabled : true


    initialize : (options = {}) ->
      super options

      @proposal = options.model

      @listenTo @options.parent_controller, 'point:open', (point) =>
        @trigger 'point:open', point

      @listenTo App.vent, 'user:signin:data_loaded', =>
        current_user = App.request 'user:current'
        if @model.get('user_id') != current_user.id
          existing_opinion = App.request 'opinion:get_by_current_user_and_proposal', @proposal.id, false
          if !existing_opinion
            @model.setUser current_user
          else
            existing_opinion_had_included_points = _.size(existing_opinion.getInclusions()) > 0
            existing_opinion.subsume @model
            @trigger 'auth_status_changed', existing_opinion_had_included_points

        @options.parent_controller.saveOpenPoint()
        @region.reset()
        @region.show @layout
        @options.parent_controller.restoreOpenPoint()

      # @listenTo App.vent, 'user:signout', => 
      #   if @proposal.openToPublic()
      #     @model = App.request 'opinion:get_by_current_user_and_proposal', @proposal.id
      #     @region.reset()
      #     @region.show @layout
      #     @trigger 'auth_status_changed'


      @layout = @getLayout()
      @setupLayout @layout
      # @region.open = (view) => @transition @region, view # this will set how this region handles the transitions between views
      @region.show @layout

    # transition : (region, view) ->
    #   region.$el.empty().append view.el

    stateWasChanged : ->
      # if @prior_state != @state
      #   @layout = @resetLayout @layout


      if @prior_state != @state

        if @state == Proposal.State.Crafting

          if @prior_state == Proposal.State.Summary
            _.delay =>
              @createFooter @layout
              @createPointsLayout @layout
            , @transition_speed()
            
          else 
            @createFooter @layout
            @createPointsLayout @layout


        else if @state == Proposal.State.Summary
          @createFooter @layout
          @layout.reasonsRegion.reset()
          @layout.stanceRegion.reset()

    createPointsLayout : (layout) ->
      points_layout = @getPointsLayout @proposal, @model
      stance_view = @getSliderView @proposal, @model
      # explanation_view = @getOpinionExplanation @model

      @listenTo points_layout, 'show', => @setupPointsLayout points_layout
      @listenTo stance_view, 'show', => @setupSliderView stance_view

      @listenTo layout, 'point:include', (point_id) =>
        point = App.request 'point:get', point_id
        @trigger 'point:include', point


      layout.reasonsRegion.show points_layout
      layout.stanceRegion.show stance_view
      # layout.explanationRegion.show explanation_view

    createHeader : (layout) ->
      header_view = @getDecisionBoardHeading @model
      layout.headerRegion.show header_view

    createFooter : (layout) ->
      footer_view = @getFooterView @model
      if footer_view
        @listenTo footer_view, 'show', => @setupFooterLayout footer_view
        layout.footerRegion.show footer_view
      else
        if layout.footerRegion.currentView
          layout.footerRegion.currentView.$el.fadeOut ->
            layout.footerRegion.reset()

    setupLayout : (layout) ->
      @listenTo layout, 'show', =>
        @model = @proposal.getUserOpinion()

        if @state == Proposal.State.Crafting
          @createPointsLayout layout

        @createFooter layout
        @createHeader layout
      
    setupFooterLayout : (view) ->
      @listenTo view, 'opinion:canceled', =>
        # TODO: discard changes?
        App.navigate Routes.proposal_path(@proposal.id), {trigger: true}

      @listenTo view, 'opinion:submit_requested', (follow_proposal) => 

        submitOpinion = =>
          @listenToOnce @model, 'opinion:synced', =>
            current_user = App.request 'user:current'
            # App.execute 'notify:success', "Thanks #{current_user.firstName()}!"

            App.navigate Routes.proposal_path( @model.get('long_id') ), {trigger: true}
            
            current_user.setFollowing 
              followable_type : 'Proposal'
              followable_id : @model.getProposal().get('id')
              follow : follow_proposal
              explicit: true

            @trigger 'opinion:published'

          @listenToOnce @model, 'opinion:sync:failed', =>
            App.execute 'notify:failure', "We're sorry, something went wrong saving your opinion"
          params = 
            follow_proposal : follow_proposal

          App.request 'opinion:sync', @model, params

        user = @model.getUser()
        if user.isNew() || user.id < 0
          App.vent.trigger 'signin:requested'
          @listenToOnce App.vent, 'user:signin', => 
            @stopListening App.vent, 'user:signin:canceled'

            @listenToOnce App.vent, 'user:signin:data_loaded', =>
              # wait for content to be loaded for user, otherwise weird combinations occur
              submitOpinion()

          @listenToOnce App.vent, 'user:signin:canceled', =>
            # if user cancels login, then we could later submit this opinion unexpectedly when signing in to submit a different opinion!      
            @stopListening App.vent, 'user:signin'
        else
          submitOpinion()

    setupPointsLayout : (layout) ->
      @decision_board_pros_controller.close() if @decision_board_pros_controller
      @decision_board_cons_controller.close() if @decision_board_cons_controller

      points = App.request 'points:get_by_proposal', @proposal.id
      included_points = @model.getIncludedPoints()

      decision_board_pros = new App.Entities.Points 
      decision_board_cons = new App.Entities.Points
      
      @decision_board_pros_controller = @getPointsController layout.decisionBoardProsRegion, 'pro', decision_board_pros
      @decision_board_cons_controller = @getPointsController layout.decisionBoardConsRegion, 'con', decision_board_cons

      ########
      # instead of passing these in to the constructor, going to add them after. This is so that the respective
      # PointController instances will be spun off properly by PointsController
      decision_board_pros.add points.filter (point) ->
        point.id in included_points && point.isPro()

      decision_board_cons.add points.filter (point) ->
        point.id in included_points && !point.isPro()
      ########

      @setupPointsColumnController @decision_board_pros_controller
      @setupPointsColumnController @decision_board_cons_controller

      _.each [@decision_board_pros_controller, @decision_board_cons_controller], (controller) =>
        @listenTo controller, 'point:opened', (point) =>
          @trigger 'point:opened', point

          @listenToOnce controller, 'point:closed', (point) =>
            @trigger 'point:closed', point


    setupPointsColumnController : (controller) ->

      @listenTo controller, 'point:created', (point) =>
        @model.written_points.push point
        @model.includePoint point

      @listenTo controller, 'point:remove', (view) => 
        @handleRemovePoint view, view.model, controller.options.collection

    handleIncludePoint : (model) ->
      dest_controller  = if model.isPro() then @decision_board_pros_controller else @decision_board_cons_controller
      dest = dest_controller.options.collection
      dest.add model

      @layout.processWhetherPointsHaveBeenIncluded()

    handleRemovePoint : (view, model, source) ->
      App.vent.trigger 'points:unexpand'

      source.remove model
      params =
        proposal_id : model.proposal_id,
      
      window.addCSRF params
      @model.removePoint model
      $.ajax Routes.inclusions_path( model.id ), 
        data : params
        type : 'DELETE'
        complete : (xhr) =>
          data = $.parseJSON(xhr.responseText)
          current_user = App.request 'user:current'
          current_user.setFollowing 
            followable_type : 'Point'
            followable_id : model.id
            follow : false
            explicit: false

          if data.destroyed
            model.trigger 'destroy', model, model.collection
            App.execute 'notify:success', 'Point deleted'

      @layout.processWhetherPointsHaveBeenIncluded()
      @trigger 'point:removal', model


    setupSliderView : (view) ->

    getPointsController : (region, valence, collection) ->
      new App.Franklin.Points.DecisionBoardColumnController
        valence : valence
        collection : collection
        region : region
        proposal : @proposal
        parent_controller : @
        parent_state : @state

    getLayout : ->
      new Proposal.DecisionBoardLayout
        model : @proposal.getUserOpinion()
        proposal : @proposal
        state : @state

    getPointsLayout : (proposal, opinion) ->
      new Proposal.DecisionBoardPointsLayout
        model : opinion
        proposal : proposal

    getSliderView : (proposal, opinion) ->
      new Proposal.DecisionBoardSlider
        model : opinion
        proposal : proposal

    getOpinionExplanation : (opinion) ->
      new Proposal.SummativeExplanation
        model : opinion

    getFooterView : (opinion) ->

      switch @state
        when Proposal.State.Crafting
          new Proposal.DecisionBoardFooterView
            model : opinion

        when Proposal.State.Summary
          null

        when Proposal.State.Results
          null

    getDecisionBoardHeading : (opinion) ->
      new Proposal.DecisionBoardHeading
        model : opinion      


