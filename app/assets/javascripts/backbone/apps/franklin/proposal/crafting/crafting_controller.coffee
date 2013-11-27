@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->

  class Proposal.CraftingController extends App.Controllers.StatefulController
    transition_speed : -> 
      $transition_speed = 1000
      $transition_speed

    # maps from parent state to this controller's state
    state_map : ->
      map = {}
      map[Proposal.ReasonsState.collapsed] = Proposal.ReasonsState.collapsed
      map[Proposal.ReasonsState.separated] = Proposal.ReasonsState.separated
      map[Proposal.ReasonsState.together] = Proposal.ReasonsState.together
      map

    initialize : (options = {}) ->
      super options

      @proposal = options.model

      @listenTo @options.parent_controller, 'point:show_details', (point) =>
        @trigger 'point:show_details', point

      @listenTo App.vent, 'user:signin:data_loaded', =>
        current_user = App.request 'user:current'
        if @model.get('user_id') != current_user.id
          existing_position = App.request 'position:current_user:proposal', @proposal.id, false
          if !existing_position
            @model.setUser current_user
          else
            existing_position.subsume @model
            @trigger 'signin:position_changed'

        @region.reset()
        @region.show @layout

      @listenTo App.vent, 'user:signout', => 
        @region.reset()
        @region.show @layout
        @trigger 'signin:position_changed'


      @layout = @getLayout()

      @setupLayout @layout

      # @region.open = (view) => @transition @region, view # this will set how this region handles the transitions between views
      @region.show @layout


    # transition : (region, view) ->
    #   region.$el.empty().append view.el

    processStateChange : ->
      # if @prior_state != @state
      #   @layout = @resetLayout @layout


      if @prior_state != @state

        if @state == Proposal.ReasonsState.separated

          if @prior_state == Proposal.ReasonsState.collapsed
            _.delay =>
              @createFooter @layout
              @createReasons @layout
            , @transition_speed()
            
          else 
            @createFooter @layout
            @createReasons @layout


        else if @state == Proposal.ReasonsState.collapsed
          @createFooter @layout
          @layout.reasonsRegion.reset()
          @layout.stanceRegion.reset()

    createReasons : (layout) ->
      reasons_layout = @getPositionReasons @proposal, @model
      stance_view = @getPositionStance @proposal, @model
      # explanation_view = @getPositionExplanation @model

      @listenTo reasons_layout, 'show', => @setupReasonsLayout reasons_layout
      @listenTo stance_view, 'show', => @setupStanceView stance_view

      @listenTo layout, 'point:include', (point_id) =>
        point = App.request 'point:get', point_id
        @trigger 'point:include', point


      layout.reasonsRegion.show reasons_layout
      layout.stanceRegion.show stance_view
      # layout.explanationRegion.show explanation_view

    createHeader : (layout) ->
      header_view = @getReasonsHeader @model
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
        @model = @proposal.getUserPosition()

        if @state == Proposal.ReasonsState.separated
          @createReasons layout

        @createFooter layout
        @createHeader layout
      
    setupFooterLayout : (view) ->
      @listenTo view, 'position:canceled', =>
        # TODO: discard changes?
        App.navigate Routes.proposal_path(@proposal.long_id), {trigger: true}

      @listenTo view, 'position:submit-requested', (follow_proposal) => 

        submitPosition = =>
          @listenToOnce @model, 'position:synced', =>
            current_user = App.request 'user:current'
            toastr.success "Thanks #{current_user.firstName()}. Now explore the results!"

            App.navigate Routes.proposal_path( @model.get('long_id') ), {trigger: true}
            @trigger 'position:published'

          @listenToOnce @model, 'position:sync:failed', =>
            toastr.error "We're sorry, something went wrong saving your position :-(", null,
              positionClass: "toast-top-full-width"

          params = 
            follow_proposal : follow_proposal

          App.request 'position:sync', @model, params

        user = @model.getUser()
        if user.isNew() || user.id < 0
          App.vent.trigger 'registration:requested'
          # if user cancels login, then we could later submit this position unexpectedly when signing in to submit a different position!      
          @listenToOnce App.vent, 'user:signin', => 
            @model.setUser App.request 'user:current'
            submitPosition()
        else
          submitPosition()

    setupReasonsLayout : (layout) ->
      @position_pros_controller.close() if @position_pros_controller
      @position_cons_controller.close() if @position_cons_controller

      points = App.request 'points:get:proposal', @proposal.id
      included_points = @model.getIncludedPoints()

      position_pros = new App.Entities.Points 
      position_cons = new App.Entities.Points
      
      @position_pros_controller = @getPointsController layout.positionProsRegion, 'pro', position_pros
      @position_cons_controller = @getPointsController layout.positionConsRegion, 'con', position_cons

      ########
      # instead of passing these in to the constructor, going to add them after. This is so that the respective
      # PointController instances will be spun off properly by PointsController
      position_pros.add points.filter (point) ->
        point.id in included_points && point.isPro()

      position_cons.add points.filter (point) ->
        point.id in included_points && !point.isPro()
      ########

      @setupPointsController @position_pros_controller
      @setupPointsController @position_cons_controller

      _.each [@position_pros_controller, @position_cons_controller], (controller) =>
        @listenTo controller, 'point:showed_details', (point) =>
          @trigger 'point:showed_details', point

          @listenToOnce controller, 'details:closed', (point) =>
            @trigger 'details:closed', point


    setupPointsController : (controller) ->

      @listenTo controller, 'point:created', (point) =>
        @model.written_points.push point
        @model.includePoint point

      @listenTo controller, 'point:remove', (view) => 
        @handleRemovePoint view, view.model, controller.options.collection

    handleIncludePoint : (model) ->
      dest_controller  = if model.isPro() then @position_pros_controller else @position_cons_controller
      dest = dest_controller.options.collection
      dest.add model

      @layout.processIncludedPoints()



    handleRemovePoint : (view, model, source) ->
      App.vent.trigger 'points:unexpand'

      source.remove model
      params =
        proposal_id : model.proposal_id,
        point_id : model.id
      
      window.addCSRF params
      @model.removePoint model
      $.post Routes.inclusions_path( {delete : true} ), params, (data) =>
        current_user = App.request 'user:current'
        current_user.setFollowing 
          followable_type : 'Point'
          followable_id : model.id
          follow : false
          explicit: false

        if data.destroyed
          model.trigger 'destroy', model, model.collection
          toastr.success 'Point deleted'

      @trigger 'point:removal', model


    setupStanceView : (view) ->

    getPointsController : (region, valence, collection) ->
      new App.Franklin.Points.UserReasonsController
        valence : valence
        collection : collection
        region : region
        proposal : @proposal
        parent_controller : @
        parent_state : @state

    getLayout : ->
      new Proposal.PositionLayout
        model : @proposal.getUserPosition()
        proposal : @proposal
        state : @state

    getPositionReasons : (proposal, position) ->
      new Proposal.PositionReasonsLayout
        model : position
        proposal : proposal

    getPositionStance : (proposal, position) ->
      new Proposal.PositionStance
        model : position
        proposal : proposal

    getPositionExplanation : (position) ->
      new Proposal.PositionExplanation
        model : position

    getFooterView : (position) ->

      switch @state
        when Proposal.ReasonsState.separated
          new Proposal.PositionFooterSeparatedView
            model : position

        when Proposal.ReasonsState.collapsed
          null

        when Proposal.ReasonsState.together
          null

    getReasonsHeader : (position) ->
      new Proposal.ReasonsHeaderView
        model : position      


