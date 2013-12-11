@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->

  class Proposal.AggregateController extends App.Controllers.StatefulController
    transitions_enabled : true

    state_map : ->
      map = {}
      map[Proposal.State.collapsed] = Proposal.ReasonsState.collapsed
      map[Proposal.State.expanded.crafting] = Proposal.ReasonsState.separated
      map[Proposal.State.expanded.results] = Proposal.ReasonsState.together
      map

    initialize : (options = {}) ->
      super options

      @model = options.model

      @listenTo @options.parent_controller, 'point:mouseover', (includers) =>
        @histogram_view.highlightUsers includers

      @listenTo @options.parent_controller, 'point:mouseout', (includers) =>
        @histogram_view.highlightUsers includers, false

      @layout = @getLayout()

      @setupLayout @layout

      # @region.open = (view) => @transition @region, view # this will set how this region handles the transitions between views

      @region.show @layout

    # transition : (region, view) ->
    #   region.$el.empty().append view.el


    processStateChange : ->
      if @state == Proposal.ReasonsState.together || (@state == Proposal.ReasonsState.separated && @prior_state != Proposal.ReasonsState.together)
        #reset the layout such that updated positions are shown correctly in the histogram
        @createHistogram @layout


    setupLayout : (layout) ->
      @listenTo layout, 'show', =>

        if @state == Proposal.ReasonsState.together
          @createHistogram layout

        if @model.openToPublic() && App.request('tenant:get').get('enable_sharing')
          social_view = @getSocialMediaView()
          layout.socialMediaRegion.show social_view
          console.log layout.socialMediaRegion.$el

    updateHistogram : ->
      @histogram_view.close() if @histogram_view
      @histogram_view = null
      @createHistogram @layout

    createHistogram : (layout) ->
      if !@histogram_view
        @histogram_view = @getAggregateHistogram()
        @listenTo @histogram_view, 'show', => 
          @listenTo @histogram_view, 'histogram:segment_results', (segment, hard_select) =>
            if @state == Proposal.ReasonsState.together
              @trigger 'histogram:segment_results', segment
              @histogram_view.finishSelectingBar segment, hard_select
        layout.histogramRegion.show @histogram_view 





    _createHistogram : () ->
      $histogram_bar_height = 145
      $histogram_bar_width = 70

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
        full_size = Math.ceil(height * $histogram_bar_height)
        empty_size = $histogram_bar_height * (1 - height)

        tile_size = window.getTileSize($histogram_bar_width, full_size, bar.positions.length)

        tiles_per_row = Math.floor( $histogram_bar_width / tile_size)

        _.extend bar, 
          tile_size : tile_size
          full_size : full_size
          empty_size : empty_size
          num_ghosts : if bar.positions.length % tiles_per_row != 0 then tiles_per_row - bar.positions.length % tiles_per_row else 0
          bucket : idx
          group_name : App.Entities.Position.stance_name 6 - idx

        bar.positions = _.sortBy bar.positions, (pos) -> 
          !pos.getUser().get('avatar_file_name')?

      histogram

    getAggregateHistogram : ->
      new Proposal.AggregateHistogram
        model : @model
        histogram : @_createHistogram()

    getSocialMediaView : ->
      new Proposal.SocialMediaView
        model : @model

    getLayout : ->
      new Proposal.AggregateLayout
        model : @model
        state : @state
      