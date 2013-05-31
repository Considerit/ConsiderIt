class ConsiderIt.ResultsView extends Backbone.View
  PARTICIPANT_WIDTH : 150
  PARTICIPANT_HEIGHT : 130

  initialize : (options) ->

    num_participants = ($.parseJSON(@model.get('participants'))||[]).length
    @tile_size = Math.min 50, ConsiderIt.utils.get_tile_size(@PARTICIPANT_WIDTH, @PARTICIPANT_HEIGHT, num_participants)

  render : ->     
    @show_summary()
    this

  show_summary : ->
    @view.remove if @view

    @view = new ConsiderIt.SummaryView
      el : @$el
      model : @model
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
      model : @model
      tile_size : @tile_size

    @$el.hide()

    @$el
      .removeClass('m-results-summary')
      .addClass('m-aggregated-results')

    @view.render()

    @$el.show()

    #me = this
    #window.delay 500, -> 
    #  me.explode_participants()
    @trigger 'ResultsExplorer:rendered'
    
    @state = 1


  implode_participants : ->
    
    @trigger 'results:implode_participants'
    $participants = @$el.find('.l-message-speaker .l-group-container')
    $participants.find('.avatar').css {position: '', zIndex: '', '-ms-transform': "", '-moz-transform': "", '-webkit-transform': "", transform: ""}

    @$el.find('.m-bar-percentage').fadeOut()
    @$el.find('.m-histogram').fadeOut =>
      @$el.find('.m-histogram').css('opacity', '')
      $participants.fadeIn()

  explode_participants : ->
    @trigger 'results:explode_participants'

    modern = Modernizr.csstransforms && Modernizr.csstransitions

    $participants = @$el.find('.l-message-speaker .l-group-container')

    if !modern
      @$el.find('.m-histogram').css 'opacity', 1
      $participants.fadeOut()
    else
      speed = 750
      from_tile_size = $participants.find('.avatar:first').width()
      to_tile_size = @$el.find(".m-histogram .avatar:first").width()
      ratio = to_tile_size / from_tile_size

      # compute all offsets first, before applying changes, for perf reasons
      positions = {}
      for participant in $participants.find('.avatar')
        $from = $(participant)
        id = $from.data('id')
        $to = @$el.find(".m-histogram #avatar-#{id}")

        to_offset = $to.offset()
        from_offset = $from.offset()

        offsetX = to_offset.left - from_offset.left
        offsetY = to_offset.top - from_offset.top

        offsetX -= (from_tile_size - to_tile_size)/2
        offsetY -= (from_tile_size - to_tile_size)/2

        positions[id] = [offsetX, offsetY]

      for participant in $participants.find('.avatar')
        $from = $(participant)
        id = $from.data('id')
        [offsetX, offsetY] = positions[id]
        
        $from.css 
          #'-o-transform': "scale(#{ratio},#{ratio}) translate(#{ 1/ratio * offsetX}px,#{ 1/ratio * offsetY}px)",
          '-ms-transform': "scale(#{ratio},#{ratio}) translate(#{ 1/ratio * offsetX}px,#{ 1/ratio * offsetY}px)",
          '-moz-transform': "scale(#{ratio},#{ratio}) translate(#{ 1/ratio * offsetX}px,#{ 1/ratio * offsetY}px)",
          '-webkit-transform': "scale(#{ratio},#{ratio}) translate(#{ 1/ratio * offsetX}px,#{ 1/ratio * offsetY}px)",
          'transform': "scale(#{ratio},#{ratio}) translate(#{ 1/ratio * offsetX}px,#{ 1/ratio * offsetY}px)"

      me = this
      window.delay speed + 150, -> 
        me.$el.find('.m-histogram').css 'opacity', 1
        
        #window.delay 25, -> 
        $participants.fadeOut()
        me.$el.find('.m-bar-percentage').fadeIn()
 

  events : 
    #'click .m-results-responders, .l-message-speaker.l-group-container' : 'transition_explorer'
    'click [data-action="results-explode-participants"]' : 'explode_participants'
    'click [data-action="results-implode-participants"]' : 'implode_participants'

  #transition_explorer : ->
  #  ConsiderIt.router.navigate(Routes.proposal_path( @model.get('long_id') ), {trigger: true}) if @state==0

class ConsiderIt.SummaryView extends Backbone.View
  @template : _.template( $("#tpl_summary").html() )

  initialize : (options) ->
    @tile_size = options.tile_size

  render : () ->
    
    if @model.has_participants()
      this.$el.html ConsiderIt.SummaryView.template($.extend({}, @model.attributes, {
        top_pro : @model.top_pro 
        top_con : @model.top_con
        tile_size : @tile_size   
        participants : _.sortBy($.parseJSON(@model.get('participants')), (user) -> !ConsiderIt.users[user].get('avatar_file_name')?  )
        avatar : window.PaperClip.get_avatar_url(ConsiderIt.users[@model.get('user_id')], 'original')

        }))

    this

class ConsiderIt.ExplorerView extends Backbone.View

  @template : _.template( $("#tpl_results").html() )

  BARHEIGHT : 235
  BARWIDTH : 51

  initialize : (options) -> 
    @histogram = @create_histogram()
    @tile_size = options.tile_size

    @pointlists = 
      pros : new ConsiderIt.PaginatedPointList({perPage : 5} )
      cons : new ConsiderIt.PaginatedPointList({perPage : 5} )

    @pointlists.pros.reset(@model.pros)
    @pointlists.cons.reset(@model.cons)


  render : () -> 

    @hide()

    @$el.html ConsiderIt.ExplorerView.template _.extend {}, @model.attributes, 
      histogram : @histogram
      tile_size : @tile_size
      participants : _.sortBy($.parseJSON(@model.get('participants')), (user) -> !ConsiderIt.users[user].get('avatar_file_name')?  )

    @views =
      pros : new ConsiderIt.PaginatedPointListView({collection : @pointlists.pros, el : @$el.find('.m-pro-con-list-propoints'), location: 'results', proposal : @model})
      cons : new ConsiderIt.PaginatedPointListView({collection : @pointlists.cons, el : @$el.find('.m-pro-con-list-conpoints'), location: 'results', proposal : @model})

    @$histogram = @$el.find('.m-histogram')

    @pointlists.pros.setSort('score', 'desc')
    @pointlists.cons.setSort('score', 'desc')

    @show()

    #$('body').animate {scrollTop: @$el.offset().top}, 1000      


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

    for id, pos of @model.positions
      histogram.breakdown[6-pos.get('stance_bucket')].positions.push(pos) if pos.get('user_id') > -1

    _.extend histogram, 
      biggest_segment : Math.max.apply(null, _.map(histogram.breakdown, (bar) -> bar.positions.length))
      num_positions : if !@model.has_participants() then 0 else _.keys(@model.positions).length

    for bar,idx in histogram.breakdown
      height = bar.positions.length / histogram.biggest_segment
      full_size = Math.ceil(height * @BARHEIGHT)
      empty_size = @BARHEIGHT * (1 - height)

      tile_size = ConsiderIt.utils.get_tile_size(@BARWIDTH, full_size, bar.positions.length)

      tiles_per_row = Math.floor( @BARWIDTH / tile_size)

      _.extend bar, 
        tile_size : tile_size
        full_size : full_size
        empty_size : empty_size
        num_ghosts : if bar.positions.length % tiles_per_row != 0 then tiles_per_row - bar.positions.length % tiles_per_row else 0

      bar.positions = _.sortBy bar.positions, (pos) -> 
        !ConsiderIt.users[pos.get('user_id')].get('avatar_file_name')?
    histogram

  #handlers
  events : 
    'mouseenter .m-point-results' : 'highlight_point_includers'
    'mouseleave .m-point-results' : 'highlight_point_includers'
    #'mouseenter .m-bar-is-hard-selected .m-bar-person' : 'show_user_explanation' 
    #'mouseleave .m-bar-is-hard-selected .m-bar-person' : 'hide_user_explanation' 
    'mouseenter .m-histogram-bar:not(.m-bar-is-selected)' : 'select_bar'
    'click .m-histogram-bar:not(.m-bar-is-hard-selected)' : 'select_bar'
    'click .m-bar-is-hard-selected' : 'deselect_bar'
    #'mouseleave .m-bar-is-soft-selected' : 'deselect_bar'
    'mouseleave .m-histogram' : 'deselect_bar'
    'keypress' : 'deselect_bar'
    'click .point_filter:not(.selected)' : 'sort_all'
    'click .m-point-wrap' : 'navigate_point_details'

  navigate_point_details : (ev) ->
    point_id = $(ev.currentTarget).closest('.pro, .con').data('id')
    ConsiderIt.router.navigate(Routes.proposal_point_path(@model.get('long_id'), point_id), {trigger: true})


  select_bar : (ev) ->

    $target = $(ev.currentTarget)
    hard_select = ev.type == 'click'

    if ( hard_select || @$histogram.find('.m-bar-is-hard-selected').length == 0 )
      @$histogram.addClass 'm-histogram-segment-selected'
      @$el.find('.m-bar-percentage').hide()

      $bar = $target.closest('.m-histogram-bar')
      bubble_offset = $bar.offset().top - @$el.find('.l-message-body').offset().top + 20

      @$el.hide()

      bucket = 6 - $bar.attr('bucket')
      $('.m-bar-is-selected', @$histogram).removeClass('m-bar-is-selected m-bar-is-hard-selected m-bar-is-soft-selected')
      $bar.addClass("m-bar-is-selected #{if hard_select then 'm-bar-is-hard-selected' else 'm-bar-is-soft-selected'}")

      vw.$el.hide() for vw in @views

      fld = "score_stance_group_#{bucket}"

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

      @pointlists.pros.updateList()
      @pointlists.cons.updateList()

      others = @$el.find('.m-results-pro-con-list-who-others')
      others.siblings('.m-results-pro-con-list-who-all').hide()
      others
        .html("The most compelling considerations for us <span class='group_name'>#{ConsiderIt.Position.stance_name(bucket)}</span>")
        .show()

      #@$el.find('.l-message-body .t-bubble').hide()
      @$el.find('.l-message-speaker').css('z-index': 999)

      #@$el.find('.t-bubble-bar').remove()


      #$bar_bubble = $('<div class="t-bubble-bar t-bubble"><div class="t-bubble-wrap">&#9654;</div></div>')
      #$bar_bubble.css('top', bubble_offset)
      #@$el.find('.l-message-body').append($bar_bubble)

      for vw in @views
        #vw.repaginate()
        vw.$el.show()

      #######
      # when clicking outside of bar, close it
      if hard_select
        $(document).click (ev) => @close_bar_click()
        $(document).keyup (ev) => @close_bar_key(ev)
        ev.stopPropagation()
      #######

      @$el.show()

  close_bar_click : (ev) ->
    @deselect_bar()

  close_bar_key : (ev) ->
    if ev.keyCode == 27 && $('#registration_overlay').length == 0
      @deselect_bar()
  
  deselect_bar : (ev) ->

    $selected_bar = @$histogram.find('.m-bar-is-selected')
    return if $selected_bar.length == 0 || (ev && ev.type == 'mouseleave' && $selected_bar.is('.m-bar-is-hard-selected'))

    @$histogram.removeClass 'm-histogram-segment-selected'
    @$el.find('.m-bar-percentage').show()

    hiding = @$el.find('.m-point-list, .m-results-pro-con-list-who')
    hiding.css 'visibility', 'hidden'


    @pointlists.pros.setSort('score', 'desc')
    @pointlists.cons.setSort('score', 'desc')
    @pointlists.pros.setFieldFilter()
    @pointlists.cons.setFieldFilter()

    @pointlists.cons.updateList()
    @pointlists.pros.updateList()

    aggregate_heading = @$el.find('.m-results-pro-con-list-who-all')
    aggregate_heading.siblings('.m-results-pro-con-list-who-others').hide()
    aggregate_heading.show()

    $('.m-bar-person-details:visible', $selected_bar).hide()

    @$el.find('.l-message-speaker').css('z-index': '')

    hiding.css 'visibility', ''

    $selected_bar.removeClass('m-bar-is-selected m-bar-is-hard-selected m-bar-is-soft-selected')

    $(document).unbind 'click', @close_bar_click
    $(document).unbind 'keyup', @close_bar_key
  

  show_user_explanation : (ev) ->
    $(ev.currentTarget).find('.m-bar-person-details').show()

  hide_user_explanation : (ev) ->
    $(ev.currentTarget).find('.m-bar-person-details').hide()

  highlight_point_includers : (ev) ->

    return if @$el.find('.m-point-expanded').length > 0

    $target = $(ev.currentTarget)

    includers = $.parseJSON($target.attr('includers'))
    selector = []

    for i in [0..includers.length] by 1
      selector.push "#avatar-#{includers[i]}" 
    selector.push "#avatar-#{$target.attr('user')}"

    #TODO: use CSS3 transitions instead    
    if @$histogram.is(':visible')
      @$histogram.hide()

      if ev.type == 'mouseenter'
        @$histogram.addClass 'm-histogram-segment-selected'
        @$histogram.find('.avatar').hide()
        $(selector.join(','), @$histogram).css {'display': '', 'opacity': 1}
        @$histogram.find('.m-bar-percentage').hide()
      else
        @$histogram.removeClass 'm-histogram-segment-selected'
        @$histogram.find('.avatar').css {'display': '', 'opacity': ''} 
        @$histogram.find('.m-bar-percentage').show()

      @$histogram.show()

    else
      $group_container = @$el.find('.l-group-container')
      $group_container.hide()

      if ev.type == 'mouseenter'
        $group_container.find('.avatar').hide()
        $(selector.join(','), $group_container).css {'display': '', 'opacity': 1}
      else
        $group_container.find('.avatar').css {'display': '', 'opacity': ''} 

      $group_container.show()


  sort_all : (ev) ->
    $target = $(ev.currentTarget)
    fld = $target.data('filter')

    @pointlists.pros.setSort(fld, 'desc', true)
    @pointlists.cons.setSort(fld, 'desc', true)

    @pointlists.pros.updateList()
    @pointlists.cons.updateList()

    $target.siblings().removeClass('selected')
    $target.addClass('selected')

