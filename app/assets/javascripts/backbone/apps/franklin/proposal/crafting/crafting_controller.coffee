@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->
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

        @listenTo App.vent, 'user:signin', =>
          current_user = App.request 'user:current'

          _.each @model.written_points, (pnt) =>
            pnt.set 'user_id', current_user.id

        @listenTo ConsiderIt.vent, 'user:signout', => 
          @region.reset()
          @region.show layout

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

          xhr = Backbone.sync 'update', @model,
            data : JSON.stringify params
            contentType : 'application/json'

            success : (data) =>
              @model.set data.position.position
              @model.getProposal().newPositionSaved @model

              #TODO: make sure points getting updated properly in all containers
              App.trigger 'points:fetched', (p.point for p in data.updated_points)

              # if @$el.data('activity') == 'proposal-no-activity' && @model.has_participants()
              #   @$el.attr('data-activity', 'proposal-has-activity')

              current_user = App.request 'user:current'
              toastr.success "Thanks for your contribution #{current_user.firstName()}. Now explore the results!", null,
                positionClass: "toast-top-full-width"
                fadeIn: 100
                fadeOut: 100
                timeOut: 15000
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

      window.addCSRF params
      @model.removePoint model
      $.post Routes.inclusions_path( {delete : true} ), params
      App.vent.trigger 'point:removal', model.id


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
      window.addCSRF params
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
