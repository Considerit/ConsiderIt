@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->

  class Proposal.CraftingController extends App.Controllers.StatefulController
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
      @model = @proposal.getUserPosition()

      @listenTo @options.parent_controller, 'point:show_details', (point) =>
        @trigger 'point:show_details', point

      @layout = @getLayout()

      @setupLayout @layout

      @region.open = (view) => @transition @region, view # this will set how this region handles the transitions between views
      @region.show @layout


    transition : (region, view) ->
      if @state == Proposal.ReasonsState.collapsed
        region.$el.empty().append view.el
      else if @state == Proposal.ReasonsState.separated
        if @prior_state == null
          region.$el.empty().append view.el
        else
          _.delay =>
            view.$el.hide()
            region.$el.empty().append view.el
            view.$el.fadeIn 400
          , 400
      else if @state == Proposal.ReasonsState.together
        view.$el.hide()
        region.$el.empty().append view.el


    processStateChange : ->
      if @prior_state != @state
        @layout = @resetLayout @layout


    setupLayout : (layout) ->
      @listenTo layout, 'show', =>
        # switch @state 

        #   when Proposal.ReasonsState.separated
        @setupPositionLayout layout

        @listenTo App.vent, 'user:signin', =>
          current_user = App.request 'user:current'

          _.each @model.written_points, (pnt) =>
            pnt.set 'user_id', current_user.id

        @listenTo ConsiderIt.vent, 'user:signout', => 
          #TODO: clear out position data like points
          @region.reset()
          @region.show layout


    setupPositionLayout : (layout) ->

      reasons_layout = @getPositionReasons @proposal, @model
      stance_view = @getPositionStance @proposal, @model
      # explanation_view = @getPositionExplanation @model

      @listenTo reasons_layout, 'show', => 
        @setupReasonsLayout reasons_layout
      @listenTo stance_view, 'show', => @setupStanceView stance_view

      layout.reasonsRegion.show reasons_layout
      layout.stanceRegion.show stance_view
      # layout.explanationRegion.show explanation_view

      footer_view = @getFooterView @model
      @listenTo footer_view, 'show', => @setupFooterLayout footer_view
      layout.footerRegion.show footer_view
      
    setupFooterLayout : (view) ->
      @listenTo view, 'position:canceled', =>
        # TODO: discard changes?
        App.navigate Routes.proposal_path(@proposal.long_id), {trigger: true}

      @listenTo view, 'position:submit-requested', (follow_proposal) => 
        submitPosition = =>
          params = _.extend @model.toJSON(),    
            included_points : @model.getIncludedPoints()
            viewed_points : _.keys(@model.viewed_points)
            follow_proposal : follow_proposal

          xhr = Backbone.sync 'update', @model,
            data : JSON.stringify params
            contentType : 'application/json'

            success : (data) =>
              #TODO : move this to Position.coffee
              proposal = @model.getProposal()

              @model.set data.position.position

              App.vent.trigger 'points:fetched', (p.point for p in data.updated_points)
              proposal.set(data.proposal) if 'proposal' of data

              App.vent.trigger('position:subsumed', data.subsumed_position.position) if 'subsumed_position' of data && data.subsumed_position && data.subsumed_position.id != @model.id
              proposal.newPositionSaved @model

              #TODO: make sure points getting updated properly in all containers

              # if @$el.data('activity') == 'proposal-no-activity' && @model.has_participants()
              #   @$el.attr('data-activity', 'proposal-has-activity')

              current_user = App.request 'user:current'
              toastr.success "Thanks #{current_user.firstName()}. Now explore the results!", null,
                positionClass: "toast-top-full-width"
                fadeIn: 100
                fadeOut: 100
                timeOut: 7000
                extendedTimeOut: 100

              App.navigate Routes.proposal_path( @model.get('long_id') ), {trigger: true}


            failure : (data) =>
              toastr.error "We're sorry, something went wrong saving your position :-(", null,
                positionClass: "toast-top-full-width"

          App.execute 'show:loading',
            loading:
              entities : xhr
              xhr: true

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
        model : @model
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
      new Proposal.PositionFooterView
        model : position
