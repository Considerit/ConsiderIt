@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->
  class Proposal.ReasonsController extends App.Controllers.StatefulController
    transitions_enabled : true


    initialize : (options = {}) ->
      super options

      @model = options.model

      @listenTo @options.parent_controller, 'point:open', (point) =>
        @trigger 'point:open', point

      # @listenTo App.vent, 'user:signout', =>
      #   @crafting_controller.close() if @crafting_controller
      #   @crafting_controller = @getCraftingController @layout.opinionRegion        
      #   @setupCraftingController @crafting_controller 
      #   @trigger 'auth_status_changed'

      @layout = @getLayout()
      @setupLayout @layout

      @region.show @layout

    # transition or reset views as appropriate after state has been updated
    stateWasChanged : ->
      
      participants_view = @getParticipantsView()
      @layout.participantsRegion.show participants_view

      if @state == Proposal.State.Summary
        @layout.footerRegion.show @getViewResultsView()
      else
        @layout.footerRegion.reset()

      wait = if @crafting_controller && @prior_state != null then @transition_speed() else 0
      _.delayIfWait wait, =>


        @updateCommunityPoints @layout

        if !@crafting_controller #&& @options.model.fetched && @state != Proposal.State.Summary
          @crafting_controller = @getCraftingController @layout.opinionRegion
          @setupCraftingController @crafting_controller 


      if @layout.$el.is('.transitioning')
        @layout.sizeToFit 10
        # @layout.sizeToFit @transition_speed() / 2
        # @layout.sizeToFit @transition_speed()
        # @layout.sizeToFit @transition_speed() + 10
        @layout.sizeToFit @transition_speed() + 100

      else
        @layout.sizeToFit()

    setupLayout : (layout) ->

      @listenTo layout, 'show', =>
        @listenTo layout, 'point:viewed', (point_id) =>
          opinion = @model.getUserOpinion()
          opinion.addViewedPoint point_id if opinion

        @listenTo layout, 'show_results', =>
          if @state == Proposal.State.Summary
            App.navigate Routes.proposal_path(@model.id), {trigger: true}

        @stateWasChanged()

    updateCommunityPoints : (layout) ->
      
      if @community_pros_controller && @community_cons_controller
        all_points = App.request 'points:get_by_proposal', @model.id
        @community_pros_controller.options.collection.fullCollection.add all_points.filter((point) -> point.isPro()) 
        @community_cons_controller.options.collection.fullCollection.add all_points.filter((point) -> !point.isPro())


        _.each [@community_pros_controller, @community_cons_controller], (controller) =>
          collection = controller.options.collection
          switch @state 
            when Proposal.State.Crafting
              included_points = @model.getUserOpinion().getIncludedPoints()              
              collection.fullCollection.remove (App.request('point:get', i) for i in included_points)
              collection.setPageSize 4
              controller.sortPoints 'persuasiveness'

            when Proposal.State.Summary
              top_points = [@model.get('top_pro'), @model.get('top_con')]
              collection.fullCollection.set top_points

              collection.setPageSize 1

            when Proposal.State.Results
              collection.setPageSize 4
              controller.sortPoints 'score'

      else
        points = switch @state 
          when Proposal.State.Summary
            page_size = 1
            App.request 'points:get_top_points_for_proposal', @model.id
          when Proposal.State.Crafting
            included_points = @model.getUserOpinion().getIncludedPoints()
            all_points = App.request 'points:get_by_proposal', @model.id
            page_size = 4
            new App.Entities.Points all_points.filter (point) -> !(point.id in included_points)
          else
            page_size = 4
            App.request 'points:get_by_proposal', @model.id

        community_pros = new App.Entities.PaginatedPoints points.filter((point) -> point.isPro()), {state: {pageSize:page_size} }
        community_cons = new App.Entities.PaginatedPoints points.filter((point) -> !point.isPro()), {state: {pageSize:page_size} }


        @community_pros_controller = @getCommunityPointsController layout.communityProsRegion, 'pro', community_pros
        @community_cons_controller = @getCommunityPointsController layout.communityConsRegion, 'con', community_cons

        _.each [ [@community_pros_controller, @community_cons_controller], [@community_cons_controller, @community_pros_controller]], (item) =>
          [controller, other_controller] = item
          @listenTo controller, 'point:opened', (point) =>
            @layout.pointWasOpened controller.region

            @listenToOnce controller, 'point:closed', (point) =>
              @layout.pointWasClosed controller.region

          @listenTo controller, 'points:expand', (valence) =>

            if other_controller.is_expanded
              other_controller.toggleExpanded other_controller.is_expanded

            @layout.pointsWereExpanded valence

            @listenToOnce controller, 'points:unexpand', (valence) =>
              @layout.pointsWereUnexpanded valence


        @setupPointsColumnController @community_pros_controller
        @setupPointsColumnController @community_cons_controller

    segmentCommunityPoints : (segment) ->
      # @layout.reasonsHeaderRegion.show @getHeaderView(segment)

      _.each [@community_pros_controller, @community_cons_controller], (controller, idx) =>
        controller.segmentCommunityPoints segment

      @layout.sizeToFit()

    includePoint : (model) ->
      opinion = @model.getUserOpinion()
      opinion.includePoint model

      source_controller = if model.isPro() then @community_pros_controller else @community_cons_controller
      source = source_controller.options.collection
      source.remove model

      @crafting_controller.handleIncludePoint model

      params =
        proposal_id : @model.id
        point_id : model.id
      
      window.addCSRF params
      $.post Routes.inclusions_path(), 
        params, (data) =>
          current_user = App.request 'user:current'
          current_user.setFollowing 
            followable_type : 'Point'
            followable_id : model.id
            follow : true
            explicit: false

    ######################################
    # Extremely ugly two methods
    saveOpenPoint : ->
      # check if any points are open now, and, if so, save them such that we can reopen it after we are done resetting peer points
      @has_open_point = @region.$el.find('.open_point').length > 0
      if @has_open_point
        $open_point = @region.$el.find('.open_point')
        point_id = $open_point.data('id')
        @saved_point = App.request 'point:get', point_id
        @comment_text = $open_point.find('.new_comment_body_field').val()

    restoreOpenPoint : ->
      if @has_open_point
        App.navigate Routes.proposal_point_path(@saved_point.get('long_id'), @saved_point.id), {trigger : true}

        _.delay =>
          $open_point = @region.$el.find('.open_point')
          $comment_field = $open_point.find('.new_comment_body_field')
          $comment_field.val @comment_text
          $comment_field.ensureInView {scroll: false}
        , 10
        @has_open_point = null
    ###############################

    setupCraftingController : (controller) ->
      @listenTo controller, 'point:removal', (model) =>
        points_controller = if model.isPro() then @community_pros_controller else @community_cons_controller
        points_controller.options.collection.add model
        @trigger 'point:removal', model.id

      @listenTo controller, 'point:opened', (point) =>
        @layout.pointWasOpened @layout.opinionRegion

        @listenTo controller, 'point:closed', (point) => 
          @layout.pointWasClosed @layout.opinionRegion

      # After signing in, the existing user may have a preexisting opinion. We need
      # to refresh the points shown in the margins if that preexisting opinion had included points.
      # Similarily after a user signs out, the points in their list should be returned to peer points.
      @listenTo controller, 'auth_status_changed', (existing_opinion_had_included_points) =>
        if @state == Proposal.State.Crafting && existing_opinion_had_included_points

          @saveOpenPoint()
          App.vent.trigger 'points:unexpand'
          @updateCommunityPoints @layout
          @restoreOpenPoint()

      @listenTo controller, 'opinion_published', => @trigger 'opinion_published'

      @listenTo controller, 'point:include', (model) => @includePoint model


    setupPointsColumnController : (controller) ->
      @listenTo controller, 'point:highlight_includers', (view) =>
        if @state == Proposal.State.Results
          # don't highlight users on point mouseover unless the histogram is fully visible
          includers = view.model.getIncluders() || []
          includers.push view.model.get('user_id')
          @trigger 'point:highlight_includers', includers 

      @listenTo controller, 'point:unhighlight_includers', (view) =>
        if @state == Proposal.State.Results
          includers = view.model.getIncluders() || []
          includers.push view.model.get('user_id')
          @trigger 'point:unhighlight_includers', includers 

      @listenTo controller, 'point:include', (model) =>
        @includePoint model


    getCraftingController : (region) ->
      new Proposal.CraftingController
        model : @model
        region : region
        parent_state : @state
        parent_controller : @
        prior_state : @prior_state

    getCommunityPointsController : (region, valence, collection) ->
      new App.Franklin.Points.CommunityPointsController
        valence : valence
        collection : collection
        proposal : @model
        region : region
        parent_controller : @
        parent_state : @state

    getViewResultsView : ->
      new Proposal.ViewResultsView
        model : @model

    getParticipantsView : ->
      new Proposal.ParticipatingUsersView
        model : @model

    getLayout : ->
      new Proposal.ReasonsLayout
        model : @model
        state : @state



