class ConsiderIt.ResultsView extends Backbone.View
  PARTICIPANT_WIDTH : 150
  PARTICIPANT_HEIGHT : 150

  initialize : (options) ->
    @proposal = options.proposal
    num_participants = $.parseJSON(@model.get('participants')).length
    @tile_size = Math.min 50, ConsiderIt.utils.get_tile_size(@PARTICIPANT_WIDTH, @PARTICIPANT_HEIGHT, num_participants)

  render : ->     
    @show_summary()
    this

  show_summary : ->
    @view.remove if @view

    @view = new ConsiderIt.SummaryView
      el : @$el
      proposal : @proposal
      model : @proposal.model
      tile_size : @tile_size

    @$el.hide()
    @$el
      .addClass('m-results-summary')
      .removeClass('m-aggregated-results')
      .attr('data-role', 'results-section')
    @view.render()
    @$el.show()

    @state = 0

  show_explorer : ->
    @view.remove if @view
    @view = new ConsiderIt.ExplorerView
      el : @$el
      proposal : @proposal
      model : @model
      tile_size : @tile_size

    @$el.hide()
    @$el
      .removeClass('m-results-summary')
      .addClass('m-aggregated-results')

    @view.render()
    @$el.show()

    me = this
    window.delay 1000, -> 
      me.explode_participants()

    @state = 1

  explode_participants : ->
    speed = 1500

    modern = Modernizr.csstransforms && Modernizr.csstransitions

    $participants = @$el.find('.l-message-speaker')

    from_tile_size = $participants.find('.avatar:first').width()
    to_tile_size = @$el.find(".m-histogram .avatar:first").width()
    ratio = to_tile_size / from_tile_size

    if modern
      $participants
        .css({'position':'relative','z-index':99}) 
        .find('.avatar').css {
          '-o-transition': "all #{speed}ms",
          '-ms-transition': "all #{speed}ms",
          '-moz-transition': "all #{speed}ms",
          '-webkit-transition': "all #{speed}ms",
          'transition': "all #{speed}ms"}
    else
      $participants.hide()
      $participants.find('.avatar').css {
              'width' : "#{to_tile_size}px",
              'height' : "#{to_tile_size}px",
              'position' : 'relative'}
      $participants.show()

    me = this

    $.each $participants.find('.avatar'), ->
      $from = $(this)
      id = $from.data('id')
      $to = me.$el.find(".m-histogram #avatar-#{id}")

      to_offset = $to.offset()
      from_offset = $from.offset()

      offsetX = to_offset.left - from_offset.left
      offsetY = to_offset.top - from_offset.top

      if modern
        offsetX -= (from_tile_size - to_tile_size)/2
        offsetY -= (from_tile_size - to_tile_size)/2
        $from.css 
          '-webkit-transform': "scale(#{ratio},#{ratio}) translate(#{ 1/ratio * offsetX}px,#{ 1/ratio * offsetY}px)"
      else
        $from.animate {
          "left": offsetX, 
          "top": offsetY,
          }, speed, 'linear'

    window.delay speed + 350, -> 
      me.$el.find('.m-histogram-bar').css 'opacity', 1
      window.delay 400, -> 
        $participants.remove()


  events : 
    'click' : 'transition_explorer'

  transition_explorer : ->
    ConsiderIt.router.navigate(Routes.proposal_path( @proposal.model.get('long_id') ), {trigger: true}) if @state==0

class ConsiderIt.SummaryView extends Backbone.View
  @template : _.template( $("#tpl_summary").html() )

  initialize : (options) ->
    @proposal = options.proposal
    @tile_size = options.tile_size

  render : () ->

    ht = ConsiderIt.SummaryView.template($.extend({}, @model.attributes, {
      top_pro : @proposal.top_pro 
      top_con : @proposal.top_con
      tile_size : @tile_size      
      }))
              
    this.$el.html ConsiderIt.SummaryView.template($.extend({}, @model.attributes, {
      top_pro : @proposal.top_pro 
      top_con : @proposal.top_con
      tile_size : @tile_size      
      }))

    this

class ConsiderIt.ExplorerView extends Backbone.View

  @template : _.template( $("#tpl_results").html() )

  BARHEIGHT : 172
  BARWIDTH : 87

  initialize : (options) -> 
    @proposal = options.proposal
    @histogram = @create_histogram()
    @tile_size = options.tile_size

    @pointlists = 
      pros : new ConsiderIt.PaginatedPointList({perPage : 6} )
      cons : new ConsiderIt.PaginatedPointList({perPage : 6} )

    @pointlists.pros.reset(@proposal.points.pros)
    @pointlists.cons.reset(@proposal.points.cons)


  render : () -> 

    @hide()

    @$el.html ConsiderIt.ExplorerView.template _.extend {}, @model.attributes, 
      histogram : @histogram
      tile_size : @tile_size

    @views =
      pros : new ConsiderIt.PaginatedPointListView({collection : @pointlists.pros, el : @$el.find('.m-pro-con-list-propoints'), location: 'results', proposal : @proposal})
      cons : new ConsiderIt.PaginatedPointListView({collection : @pointlists.cons, el : @$el.find('.m-pro-con-list-conpoints'), location: 'results', proposal : @proposal})

    @$histogram = @$el.find('.m-histogram')

    @pointlists.pros.setSort('score', 'desc')
    @pointlists.cons.setSort('score', 'desc')

    @show()

    $('html, body').animate {scrollTop: @$el.offset().top}, 1000      
    this

  show : () ->

    @pointlists.pros.goTo(1)
    @pointlists.cons.goTo(1)

    @$el.show()

  hide : () ->
    @$el.hide()

  create_histogram : () ->
    histogram =
      breakdown : [{positions:[]} for i in [0..6]][0]

    _.each @proposal.positions, (pos) ->
      histogram.breakdown[6-pos.get('stance_bucket')].positions.push(pos)

    _.extend histogram, 
      biggest_segment : Math.max.apply(null, _.map(histogram.breakdown, (bar) -> bar.positions.length))
      num_positions : _.keys(@proposal.positions).length 

    _.each histogram.breakdown, (bar, idx) =>
      height = bar.positions.length / histogram.biggest_segment
      full_size = height * @BARHEIGHT 
      empty_size = @BARHEIGHT * (1 - height)

      tile_size = ConsiderIt.utils.get_tile_size(@BARWIDTH, full_size, bar.positions.length)

      tiles_per_row = Math.floor( @BARWIDTH / tile_size)

      _.extend bar, 
        tile_size : tile_size
        full_size : full_size
        empty_size : empty_size
        num_ghosts : if bar.positions.length % tiles_per_row != 0 then tiles_per_row - bar.positions.length % tiles_per_row else 0

    histogram

  #handlers
  events : 
    'mouseenter .m-point-results:not(#expanded)' : 'highlight_point_includers'
    'mouseleave .m-point-results:not(#expanded)' : 'highlight_point_includers'
    'mouseenter .m-bar-is-hard-selected .m-bar-person' : 'show_user_explanation' 
    'mouseleave .m-bar-is-hard-selected .m-bar-person' : 'hide_user_explanation' 
    'mouseenter .m-histogram-bar:not(.m-bar-is-selected)' : 'select_bar'
    'click .m-histogram-bar:not(.m-bar-is-hard-selected)' : 'select_bar'
    'click .m-bar-is-hard-selected' : 'deselect_bar'
    'mouseleave .m-bar-is-soft-selected' : 'deselect_bar'
    'keypress' : 'deselect_bar'
    'click .point_filter:not(.selected)' : 'sort_all'


  select_bar : (ev) ->
        
    $target = $(ev.currentTarget)
    hard_select = ev.type == 'click'

    if @$el.find('#expanded').length == 0 && ( hard_select || @$histogram.find('.m-bar-is-hard-selected').length == 0 )
      $bar = $target.closest('.m-histogram-bar')
      bucket = $bar.attr('bucket')
      $('.m-bar-is-selected', @$histogram).removeClass('m-bar-is-selected m-bar-is-hard-selected m-bar-is-soft-selected')
      $bar.addClass("m-bar-is-selected #{if hard_select then 'm-bar-is-hard-selected' else 'm-bar-is-soft-selected'}")

      fld = "score_stance_group_#{6-bucket}"

      _.each @views, (vw) -> vw.$el.hide()

      @pointlists.pros.setSort(fld, 'desc')
      @pointlists.cons.setSort(fld, 'desc')

      @pointlists.pros.setFieldFilter [{
        field : fld
        type : 'function' 
        value : (fld) -> fld > 0
      }]

      @pointlists.cons.setFieldFilter [{
        field : fld
        type : 'function' 
        value : (fld) -> fld > 0
      }]

      others = @$el.find('.m-results-pro-con-list-who-others')
      others.siblings('.m-results-pro-con-list-who-all').hide()
      others
        .html("Most important factors for <div class='group_name'>#{ConsiderIt.Position.stance_name(bucket)}</div>")
        .show()

      _.each @views, (vw) -> 
        #vw.repaginate()
        vw.$el.show()

      # $(document)
      #   .click(close_bar_click)
      #   .keyup(close_bar_key);
  
  deselect_bar : (ev) ->
    $target = $(ev.currentTarget)

    return if ev.type == 'keypress' && (ev.keyCode != 27 || $('body > .ui-widget-overlay').length > 0)
    return if ev.type == 'click' && $target.closest('pro_con_list').length > 0
    return if @$el.find('#expanded').length > 0

    $selected_bar = @$histogram.find('.m-bar-is-selected')
    return if $selected_bar.length == 0

    bucket = $selected_bar.attr('bucket')
    @pointlists.pros.setSort('score', 'desc')
    @pointlists.cons.setSort('score', 'desc')
    @pointlists.pros.setFieldFilter()
    @pointlists.cons.setFieldFilter()

    aggregate_heading = @$el.find('.m-results-pro-con-list-who-all')
    aggregate_heading.siblings('.m-results-pro-con-list-who-others').hide()
    aggregate_heading.show()

    $('.m-bar-person-details:visible', $selected_bar).hide()
    
    $selected_bar.removeClass('m-bar-is-selected m-bar-is-hard-selected m-bar-is-soft-selected')

    # $(document)
    #   .unbind('click', close_bar_click)
    #   .unbind('keyup', close_bar_key);
  

  show_user_explanation : (ev) ->
    if @$el.find('#expanded').length == 0
      $(ev.currentTarget).find('.m-bar-person-details').show()

  hide_user_explanation : (ev) ->
    if @$el.find('#expanded').length == 0
      $(ev.currentTarget).find('.m-bar-person-details').hide()

  highlight_point_includers : (ev) ->

    $target = $(ev.currentTarget)

    includers = $.parseJSON($target.attr('includers'))
    selector = []

    for i in [0..includers.length] by 1
      selector.push "#avatar-#{includers[i]}" 
    
    @$histogram.hide()

    if ev.type == 'mouseenter'
      @$histogram.find('.avatar').css('visibility', 'hidden')
      $(selector.join(','), @$histogram).css('visibility', '')
      $("#avatar-#{$target.attr('user')}").css('visibility', '')
    else
      @$histogram.find('.avatar').css('visibility', '')

    @$histogram.show()

  sort_all : (ev) ->
    $target = $(ev.currentTarget)
    fld = $target.data('filter')

    @pointlists.pros.setSort(fld, 'desc', true)
    @pointlists.cons.setSort(fld, 'desc', true)

    $target.siblings().removeClass('selected')
    $target.addClass('selected')

