@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->

  class Proposal.AggregateController extends Proposal.AbstractProposalController
    exploded : false

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
              if @exploded
                # don't highlight users on point mouseover unless the histogram is fully visible
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
              if idx of @removed_points
                collection.fullCollection.add @removed_points[idx]

              @removed_points[idx] = collection.fullCollection.filter (point) ->
                !point.get(fld) || point.get(fld) == 0


              collection.fullCollection.remove @removed_points[idx]

              collection.setSorting fld, 1
              collection.fullCollection.sort()

        layout.proposalRegion.show proposal_view
        layout.reasonsRegion.show reasons_layout
        layout.histogramRegion.show histogram_view #has to be shown after reasons

        @options.transition ?= true
        if @options.transition
          _.delay =>
            layout.explodeParticipants()
            @exploded = true
          , 750
        else
          layout.explodeParticipants false
          @exploded = true

        @options.move_to_results ?= false
        if @options.move_to_results
          layout.moveToResults()


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

        tile_size = window.getTileSize(BARWIDTH, full_size, bar.positions.length)

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