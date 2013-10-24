@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->

  class Proposal.AggregateController extends App.Controllers.StatefulController

    state_map : ->
      map = {}
      map[Proposal.State.collapsed] = Proposal.ReasonsState.collapsed
      map[Proposal.State.expanded.crafting] = Proposal.ReasonsState.separated
      map[Proposal.State.expanded.results] = Proposal.ReasonsState.together
      map

    initialize : (options = {}) ->
      super options

      @model = options.model

      @layout = @getLayout()

      @setupLayout @layout

      @region.open = (view) => @transition @region, view # this will set how this region handles the transitions between views

      @region.show @layout

    transition : (region, view) ->
      if @state == Proposal.ReasonsState.collapsed || @prior_state == null
        region.$el.empty().append view.el
      else if @state == Proposal.ReasonsState.separated
        region.$el.empty().append view.el
        view.$el.slideUp()
      else        
        region.$el.empty().append view.el


    processStateChange : ->
      if @prior_state != @state
        @layout = @resetLayout @layout

    setupLayout : (layout) ->
      @listenTo layout, 'show', =>
        @setupHistogram layout

        @listenTo @options.parent_controller, 'point:mouseover', (includers) =>
          @histogram_view.highlightUsers includers

        @listenTo @options.parent_controller, 'point:mouseout', (includers) =>
          @histogram_view.highlightUsers includers, false


    setupHistogram : (layout) ->
      @histogram_view = @getAggregateHistogram()
      @listenTo @histogram_view, 'show', => 
        @listenTo @histogram_view, 'histogram:segment_results', (segment) =>
          @trigger 'histogram:segment_results', segment

      layout.histogramRegion.show @histogram_view 

      # if @model.openToPublic()
      #   social_view = @getSocialMediaView()
      #   layout.socialMediaRegion.show social_view      


    getLayout : ->
      new Proposal.AggregateLayout
        model : @model
        state : @state

    getAggregateHistogram : ->
      new Proposal.AggregateHistogram
        model : @model
        histogram : @_createHistogram()

    getSocialMediaView : ->
      new Proposal.SocialMediaView
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