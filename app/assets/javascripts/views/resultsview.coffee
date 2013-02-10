class ConsiderIt.ResultsView extends Backbone.View

  @template : _.template( $("#tpl_results").html() )

  BARHEIGHT : 175
  BARWIDTH : 70

  initialize : (options) -> 
    @proposal = options.proposal
    @histogram = @create_histogram()

    @pointlists = 
      pros : new ConsiderIt.PaginatedPointList({perPage : 6} )
      cons : new ConsiderIt.PaginatedPointList({perPage : 6} )

    @pointlists.pros.reset(@proposal.points.pros)
    @pointlists.cons.reset(@proposal.points.cons)


  render : () -> 

    @$el.html ConsiderIt.ResultsView.template
      histogram : @histogram

    @views =
      pros : new ConsiderIt.PaginatedPointListView({collection : @pointlists.pros, el : @$el.find('#propoints'), location: 'board', proposal : @proposal})
      cons : new ConsiderIt.PaginatedPointListView({collection : @pointlists.cons, el : @$el.find('#conpoints'), location: 'board', proposal : @proposal})

    @$histogram = @$el.find('#histogram')

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
    'mouseenter .point_in_list:not(#expanded)' : 'highlight_point_includers'
    'mouseout .point_in_list:not(#expanded)' : 'highlight_point_includers'
    'mouseenter #histogram .bar.hard_select .view_statement' : 'show_user_explanation' 
    'mouseout #histogram .bar.hard_select .view_statement' : 'hide_user_explanation' 
    'mouseover #histogram .bar.full:not(.selected)' : 'select_bar'
    'click #histogram .bar.full:not(.hard_select)' : 'select_bar'
    'click #histogram .bar.selected:not(.soft_select)' : 'deselect_bar'
    'mouseleave #histogram .bar.full.soft_select' : 'deselect_bar'
    'keypress' : 'deselect_bar'
    'click .opinions .point_filter:not(.selected)' : 'sort_all'


  select_bar : (ev) ->
        
    $target = $(ev.currentTarget)
    hard_select = ev.type == 'click'

    if @$el.find('#expanded').length == 0 && ( hard_select || @$histogram.find('.hard_select').length == 0 )
      $bar = $target.closest('.bar')
      bucket = $bar.attr('bucket')
      $('.bar.selected', @$histogram).removeClass('selected hard_select soft_select')
      $bar.addClass("selected #{if hard_select then 'hard_select' else 'soft_select'}")

      fld = "score_stance_group_#{6-bucket}"

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

      others = @$el.find('.participant_connection .others')
      others.siblings('.all').hide()
      others
        .html("Most important factors for <div class='group_name'>#{ConsiderIt.Position.stance_name(bucket)}</div>")
        .show()

      #sort / filter @pointlists.pros and @pointlists.cons


      # $(document)
      #   .click(close_bar_click)
      #   .keyup(close_bar_key);
  
  deselect_bar : (ev) ->
    $target = $(ev.currentTarget)

    return if ev.type == 'keypress' && (ev.keyCode != 27 || $('body > .ui-widget-overlay').length > 0)
    return if ev.type == 'click' && $target.closest('pro_con_list').length > 0
    return if @$el.find('#expanded').length > 0

    $selected_bar = @$histogram.find('.bar.selected')
    return if $selected_bar.length == 0

    bucket = $selected_bar.attr('bucket')
    @pointlists.pros.setSort('score', 'desc')
    @pointlists.cons.setSort('score', 'desc')
    @pointlists.pros.setFieldFilter()
    @pointlists.cons.setFieldFilter()

    aggregate_heading = @$el.find('.participant_connection .all')
    aggregate_heading.siblings('.others').hide()
    aggregate_heading.show()

    $('.view_statement .details:visible', $selected_bar).hide()
    
    $selected_bar.removeClass('selected hard_select soft_select')

    # $(document)
    #   .unbind('click', close_bar_click)
    #   .unbind('keyup', close_bar_key);
  

  show_user_explanation : (ev) ->
    if @$el.find('#expanded').length == 0
      $(ev.currentTarget).children('.details').show()

  hide_user_explanation : (ev) ->
    if @$el.find('#expanded').length == 0
      $(ev.currentTarget).children('.details').hide()

  highlight_point_includers : (ev) ->
    #TODO make this more performant
    
    $target = $(ev.currentTarget)

    @$histogram.toggleClass('hovering_over_point')
    includers = $.parseJSON($target.attr('includers'))
    selector = []

    for i in [0..includers.length] by 1
      selector.push('#user-' + includers[i] + ' .view_statement img')
    
    if ev.type == 'mouseenter'
      $(selector.join(','), @$histogram).addClass('includer_of_hovered_point')
      $('#user-' + $target.attr('user') + ' .view_statement img').addClass('author_of_hovered_point')          
    else
      $(selector.join(','), @$histogram).removeClass('includer_of_hovered_point')
      $('#user-' + $target.attr('user') + ' .view_statement img').removeClass('author_of_hovered_point')    


  sort_all : (ev) ->
    $target = $(ev.currentTarget)
    fld = $target.data('filter')

    @pointlists.pros.setSort(fld, 'desc', true)
    @pointlists.cons.setSort(fld, 'desc', true)

    $target.siblings().removeClass('selected')
    $target.addClass('selected')

