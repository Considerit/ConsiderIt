@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->
  class Proposal.AbstractProposalController extends App.Controllers.Base

  class Proposal.PositionController extends Proposal.AbstractProposalController
    initialize : (options = {}) ->
      @proposal = options.model
      @model = @proposal.getUserPosition()

      layout = @getLayout @proposal
      @listenTo layout, 'show', =>
        proposal_view = @getProposalDescription @proposal
        crafting_layout = @getCraftingLayout @proposal, @model
        footer_view = @getFooterView @model

        @listenTo crafting_layout, 'show', => @setupPositionLayout crafting_layout
        @listenTo footer_view, 'show', => @setupFooterLayout footer_view

        layout.proposalRegion.show proposal_view
        layout.positionRegion.show crafting_layout
        layout.footerRegion.show footer_view

      @region.show layout
      @layout = layout

    setupPositionLayout : (layout) ->
      @listenTo layout, 'point:viewed', (point_id) =>
        @model.addViewedPoint point_id

      reasons_layout = @getPositionReasons @proposal, @model
      stance_view = @getPositionStance @model
      # explanation_view = @getPositionExplanation @model

      @listenTo reasons_layout, 'show', => @setupReasonsLayout reasons_layout
      @listenTo stance_view, 'show', => @setupStanceView stance_view

      layout.reasonsRegion.show reasons_layout
      layout.stanceRegion.show stance_view
      # layout.explanationRegion.show explanation_view
      
    setupFooterLayout : (view) ->
      @listenTo view, 'position:canceled', =>
        # TODO: discard changes
        App.navigate Routes.proposal_path(@proposal.long_id), {trigger: true}

      @listenTo view, 'position:submit-requested', (follow_proposal) => 
        submitPosition = =>
          params = _.extend @model.toJSON(),    
            included_points : @model.getIncludedPoints()
            viewed_points : _.keys(@model.viewed_points)
            follow_proposal : follow_proposal

          Backbone.sync 'update', @model,
            data : JSON.stringify params
            contentType : 'application/json'

            success : (data) =>
              @model.set data.position.position
              @model.getProposal().newPositionSaved @model

              #TODO: make sure points getting updated properly in all containers
              App.trigger 'points:fetched', (p.point for p in data.updated_points)

              # if @$el.data('activity') == 'proposal-no-activity' && @model.has_participants()
              #   @$el.attr('data-activity', 'proposal-has-activity')

              App.navigate Routes.proposal_path( @model.get('long_id') ), {trigger: true}
              #TODO: Toastr notification!

            failure : (data) =>
              #TODO: Toastr notification!
              throw 'Something went wrong syncing position'

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
      points = App.request 'points:get:proposal', @proposal.id
      included_points = @model.getIncludedPoints()
      #TODO: make sure included points is correct

      position_pros = new App.Entities.Points points.filter (point) ->
        point.id in included_points && point.isPro()

      position_cons = new App.Entities.Points points.filter (point) ->
        point.id in included_points && !point.isPro()

      peer_pros = new App.Entities.PaginatedPoints points.filter (point) ->
        !(point.id in included_points) && point.isPro()

      peer_cons = new App.Entities.PaginatedPoints points.filter (point) ->
        !(point.id in included_points) && !point.isPro()

      peer_pros_controller = new App.Franklin.Points.PeerPointsController
        valence : 'pro'
        collection : peer_pros
        region : layout.peerProsRegion
        parent : @
        parent_controller : @

      peer_cons_controller = new App.Franklin.Points.PeerPointsController
        valence : 'con'
        collection : peer_cons
        region : layout.peerConsRegion
        parent : @
        parent_controller : @

      position_pros_controller = new App.Franklin.Points.UserReasonsController
        valence : 'pro'
        collection : position_pros
        region : layout.positionProsRegion
        proposal : @proposal
        parent : @
        parent_controller : @

      position_cons_controller = new App.Franklin.Points.UserReasonsController
        valence : 'con'
        collection : position_cons
        region : layout.positionConsRegion
        proposal : @proposal
        parent : @
        parent_controller : @

      _.each [position_pros_controller, position_cons_controller], (position_list) =>

        @listenTo position_list, 'point:created', (point) =>
          @model.written_points.push point

        @listenTo position_list, 'point:remove', (view) => 
          if position_list == position_pros_controller
            [source, dest] = [position_pros, peer_pros]
          else 
            [source, dest] = [position_cons, peer_cons]
          @handleRemovePoint view, view.model, source, dest, layout

      _.each [peer_pros_controller, peer_cons_controller], (peer_list) =>
        @listenTo peer_list, 'point:include', (view) => 
          if peer_list == peer_pros_controller
            [dest, source] = [position_pros, peer_pros]
          else 
            [dest, source] = [position_cons, peer_cons]
          @handleIncludePoint view, view.model, source, dest, layout

    handleRemovePoint : (view, model, source, dest, layout) ->
      # TODO: need to close point details if point is currently expanded
      # model.trigger('point:removed') 

      source.remove model
      dest.add model

      params = { 
        proposal_id : model.proposal_id,
        point_id : model.id
      }

      ConsiderIt.utils.add_CSRF params
      @model.removePoint model
      $.post Routes.inclusions_path( {delete : true} ), params

    handleIncludePoint : (view, model, source, dest, layout) ->
      dest.add model

      # TODO: need to close point details if point is currently expanded
      # model.trigger('point:included') 

      $item = view.$el
      if $item.is('.m-point-unexpanded')
        $included_point = layout.$el.find(".m-point-position[data-id='#{model.id}']")

        $included_point.css 'visibility', 'hidden'

        item_offset = $item.offset()
        ip_offset = $included_point.offset()
        [offsetX, offsetY] = [ip_offset.left - item_offset.left, ip_offset.top - item_offset.top]

        styles = _.pick $included_point.getStyles(), ['color', 'width', 'paddingRight', 'paddingLeft', 'paddingTop', 'paddingBottom']

        _.extend styles, 
          background: 'none'
          border: 'none'
          top: offsetY 
          left: offsetX
          position: 'absolute'

        $placeholder = $('<li class="m-point-peer">')
        $placeholder.css {height: $item.outerHeight(), visibility: 'hidden'}

        $item.find('.m-point-author-avatar, .m-point-include-wrap, .m-point-operations').fadeOut(50)

        $wrap = $item.find('.m-point-wrap')
        $wrap.css 
          position: 'absolute'
          width: $wrap.outerWidth()

        $placeholder.insertAfter $item

        $wrap.css(styles).delay(500).queue (next) =>
          $item.fadeOut -> 
            source.remove model
            $placeholder.remove()
            $included_point.css 'visibility', ''
          next()
      else
        source.remove model

      # persist the inclusion ... (in future, don't have to do this until posting...)
      params = { 
        proposal_id : model.get('proposal_id'),
        point_id : model.id
      }
      ConsiderIt.utils.add_CSRF params
      $.post Routes.inclusions_path(), 
        params, (data) ->


    setupStanceView : (view) ->

    getLayout : (proposal) ->
      new Proposal.PositionLayout
        model : proposal

    getProposalDescription : (proposal) ->
      new Proposal.PositionProposalDescription
        model : proposal

    getCraftingLayout : (proposal, position) ->
      new Proposal.PositionCraftingLayout
        model : position
        proposal : proposal

    getPositionReasons : (proposal, position) ->
      new Proposal.PositionReasonsLayout
        model : position
        proposal : proposal

    getPositionStance : (position) ->
      new Proposal.PositionStance
        model : position

    getPositionExplanation : (position) ->
      new Proposal.PositionExplanation
        model : position

    getFooterView : (position) ->
      new Proposal.PositionFooterView
        model : position

  class Proposal.AggregateController extends Proposal.AbstractProposalController
    initialize : (options = {}) ->
      @model = options.model

      layout = @getLayout()

      @removed_points = {}

      @listenTo layout, 'show', =>
        proposal_view = @getProposalDescription()
        histogram_view = @getAggregateHistgram()
        reasons_layout = @getAggregateReasons()

        points = App.request 'points:get:proposal', @model.id
        aggregated_pros = new App.Entities.PaginatedPoints points.filter((point) -> point.isPro()), {state: {pageSize:5} }
        aggregated_cons = new App.Entities.PaginatedPoints points.filter((point) -> !point.isPro()), {state: {pageSize:5} }


        @listenTo reasons_layout, 'show', => 
          [@pros_controller, @cons_controller] = @setupReasonsLayout reasons_layout, aggregated_pros, aggregated_cons

          _.each [@pros_controller, @cons_controller], (controller) =>
            @listenTo controller, 'point:highlight_includers', (view) =>
              includers = view.model.getIncluders()
              includers.push view.model.get('user_id')
              histogram_view.highlightUsers includers

            @listenTo controller, 'point:unhighlight_includers', (view) =>
              includers = view.model.getIncluders()
              includers.push view.model.get('user_id')            
              histogram_view.highlightUsers includers, false


        @listenTo histogram_view, 'show', => 

          @listenTo histogram_view, 'histogram:segment_results', (segment) =>
            fld = if segment == 'all' then 'score' else "score_stance_group_#{segment}"
            reasons_layout.updateHeader segment            
            _.each [aggregated_pros, aggregated_cons], (collection, idx) =>
              collection.setSorting fld, 1
              collection.fullCollection.sort()

              if idx of @removed_points
                collection.fullCollection.add @removed_points[idx]

              @removed_points[idx] = collection.fullCollection.filter( (point) -> !point.get(fld) || point.get(fld) == 0 )

              collection.fullCollection.remove @removed_points[idx]
            @pros_controller.layout.render()
            @cons_controller.layout.render()

        layout.proposalRegion.show proposal_view
        layout.reasonsRegion.show reasons_layout
        layout.histogramRegion.show histogram_view #has to be shown after reasons

        # TODO: make transition optional
        @options.transition ?= true
        if @options.transition
          _.delay ->
            layout.explodeParticipants()
          , 750
        else
          layout.explodeParticipants false

      @region.show layout


    setupReasonsLayout : (layout, aggregated_pros, aggregated_cons) ->
      
      pros = new App.Franklin.Points.AggregatedReasonsController
        valence : 'pro'
        collection : aggregated_pros
        region : layout.prosRegion
        parent : @
        parent_controller : @

      cons = new App.Franklin.Points.AggregatedReasonsController
        valence : 'con'
        collection : aggregated_cons
        region : layout.consRegion
        parent : @
        parent_controller : @

      [pros, cons]

    getLayout : ->
      new Proposal.AggregateLayout
        model : @model

    getProposalDescription : ->
      new Proposal.AggregateProposalDescription
        model : @model

    getAggregateHistgram : ->
      new Proposal.AggregateHistogram
        model : @model
        histogram : @_createHistogram()

    getAggregateReasons : ->
      new Proposal.AggregateReasons
        model : @model


    _createHistogram : () ->
      BARHEIGHT = 200
      BARWIDTH = 78

      breakdown = [{positions:[]} for i in [0..6]][0]

      positions = @model.getPositions()
      positions.each (pos) ->
        breakdown[6-pos.get('stance_bucket')].positions.push(pos) if pos.get('user_id') > -1

      histogram =
        breakdown : _.values breakdown
        biggest_segment : Math.max.apply(null, _.map(breakdown, (bar) -> bar.positions.length))
        num_positions : positions.length

      for bar,idx in histogram.breakdown
        height = bar.positions.length / histogram.biggest_segment
        full_size = Math.ceil(height * BARHEIGHT)
        empty_size = BARHEIGHT * (1 - height)

        tile_size = ConsiderIt.utils.get_tile_size(BARWIDTH, full_size, bar.positions.length)

        tiles_per_row = Math.floor( BARWIDTH / tile_size)

        _.extend bar, 
          tile_size : tile_size
          full_size : full_size
          empty_size : empty_size
          num_ghosts : if bar.positions.length % tiles_per_row != 0 then tiles_per_row - bar.positions.length % tiles_per_row else 0
          bucket : idx

        bar.positions = _.sortBy bar.positions, (pos) -> 
          !pos.getUser().get('avatar_file_name')?

      histogram


  ##### SUMMARY ######
  class Proposal.SummaryController extends App.Controllers.Base
    initialize : (options = {}) ->
      @model = options.model || options.view.model

      @modifiable = App.request "auth:can_edit_proposal", @model
      layout = @getLayout @model

      @listenTo layout, 'show', =>
        proposal_view = @getProposalDescription @model
        @setupProposal proposal_view
        layout.proposalRegion.show proposal_view

        if @model.get 'published'
          summary_view = @getSummaryView @model
          @setupSummary summary_view
          layout.summaryRegion.show summary_view

        if @modifiable
          @setupModifiable layout, @model

    setupProposal : (view) ->
      @listenTo view, 'proposal:clicked', =>
        App.navigate Routes.new_position_proposal_path( @model.long_id ), {trigger: true}

    setupSummary : (view) ->
      view

    setupModifiable : (view, model) ->
      @listenTo view, 'proposal:published', (proposal_attrs, position_attrs) =>
        model.set proposal_attrs
        position = App.request 'position:create', position_attrs
        model.setUserPosition position.id  
        App.navigate Routes.new_position_proposal_path(model.long_id), {trigger: true}


      @listenTo view, 'status_dialog', =>

        dialogview = new Proposal.ProposalStatusDialogView
          model : model

        @listenTo dialogview, 'proposal:updated', (data) =>
          model.set {access_list: data.access_list, active: data.active, publicity: data.publicity}
          view.render()
          dialog.close()

        dialog = App.request 'dialog:new', dialogview,
          class : 'm-proposal-admin-status'

      @listenTo view, 'publicity_dialog', (view) =>
        dialogview = new Proposal.ProposalPublicityDialogView
          model : model

        @listenTo dialogview, 'proposal:updated', (data) =>
          model.set {access_list: data.access_list, active: data.active, publicity: data.publicity}
          view.render()
          dialog.close()

        dialog = App.request 'dialog:new', dialogview,
          class : 'm-proposal-admin-publicity'

    getProposalDescription : (proposal) ->
      if proposal.get 'published'
        new Proposal.SummaryProposalDescription
          model : proposal
      else
        new Proposal.UnpublishedProposalDescription
          model : proposal


    getSummaryView : (model) ->
      new Proposal.SummaryResultsView
        model : model

    getLayout : (model) ->
      if @options.view 
        view = @options.view
      else 
        if @modifiable
          view_cls = Proposal.ModifiableProposalSummaryView
        else
          view_cls = Proposal.ProposalSummaryView

        view = new view_cls
          model: model
          class : 'm-proposal'
          attributes : 
            'data-id': "#{proposal.id}"
            'data-role': 'm-proposal'
            'data-activity': if model.has_participants() then 'proposal-has-activity' else 'proposal-no-activity'
            'data-status': if model.get('active') then 'proposal-active' else 'proposal-inactive'
            'data-visibility': if model.get('published') then 'published' else 'unpublished'

      view