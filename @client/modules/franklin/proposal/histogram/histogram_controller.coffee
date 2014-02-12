@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->

  class Proposal.HistogramController extends App.Controllers.StatefulController
    transitions_enabled : true
    histogram_initialized : false

    initialize : (options = {}) ->
      super options

      @model = options.model

      @listenTo @options.parent_controller, 'point:mouseover', (includers) =>
        @layout.highlightUsers includers

      @listenTo @options.parent_controller, 'point:mouseout', (includers) =>
        @layout.highlightUsers includers, false

      @layout = @getLayout()

      @setupLayout @layout

      # @region.open = (view) => @transition @region, view # this will set how this region handles the transitions between views

      @region.show @layout

    # transition : (region, view) ->
    #   region.$el.empty().append view.el


    stateWasChanged : ->
      if @state == Proposal.State.Results || (@state == Proposal.State.Crafting && @prior_state != Proposal.State.Results)
        #reset the layout such that updated opinions are shown correctly in the histogram
        @createHistogram()


    setupLayout : (layout) ->
      @listenTo layout, 'show', =>


        @listenTo layout, 'histogram:segment_results', (segment, hard_select) =>
          if @state == Proposal.State.Results
            @trigger 'histogram:segment_results', segment
            layout.finishSelectingBar segment, hard_select

        if @state == Proposal.State.Results && !@histogram_initialized
          @createHistogram()

    # createHistogram : (layout) ->

    #   if !@histogram_view
    #     @histogram_view = @getAggregateHistogram()
    #     @listenTo @histogram_view, 'show', => 
    #     layout.histogramRegion.show @histogram_view 

    createHistogram : () ->
      $histogram_bar_height = 145
      $histogram_bar_width = 70

      breakdown = [{opinions:[]} for i in [0..6]][0]

      opinions = @model.getOpinions()
      opinions.each (pos) ->
        breakdown[6-pos.get('stance_segment')].opinions.push(pos) if pos.get('user_id') > -1

      histogram =
        breakdown : _.values breakdown
        biggest_segment : Math.max.apply(null, _.map(breakdown, (bar) -> bar.opinions.length))
        num_opinions : opinions.length

      for bar,idx in histogram.breakdown
        height = bar.opinions.length / histogram.biggest_segment
        full_size = Math.ceil(height * $histogram_bar_height)
        empty_size = $histogram_bar_height * (1 - height)

        tile_size = window.getTileSize($histogram_bar_width, full_size, bar.opinions.length)

        tiles_per_row = Math.floor( $histogram_bar_width / tile_size)

        _.extend bar, 
          tile_size : tile_size
          full_size : full_size
          empty_size : empty_size
          num_ghosts : if bar.opinions.length % tiles_per_row != 0 then tiles_per_row - bar.opinions.length % tiles_per_row else 0
          segment : idx
          group_name : App.Entities.Opinion.stance_name 6 - idx

        bar.opinions = _.sortBy bar.opinions, (pos) -> 
          !pos.getUser().get('avatar_file_name')?

      @layout.setHistogram histogram
      @histogram_initialized = true

    getLayout : ->
      new Proposal.HistogramLayout
        model : @model
        state : @state
      