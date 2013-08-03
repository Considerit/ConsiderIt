class ConsiderIt.PointListView extends Backbone.CollectionView
  @empty_template = _.template($('#tpl_pointlist_empty').html())
  @itemView : ConsiderIt.PointView
  @childClass : 'm-point'

  listSelector : '.m-point-list'


  initialize : (options) ->
    super
    @location = options.location
    @proposal = options.proposal
    #_.bindAll this
    #ConsiderIt.vent.on 'route:PointDetails', (long_id, point_id) => @show_point_details_handler(point_id) if @proposal.long_id == long_id

  # Returns an instance of the view class
  getItemView: (point)->
    new ConsiderIt.PointListView.itemView
      model: point
      collection: @collection
      proposal : @proposal
      attributes : 
        class : "m-point-unexpanded #{ConsiderIt.PointListView.childClass}-#{@location} #{if point.attributes.is_pro then 'pro' else 'con' }"
        'data-id': "#{point.id}"
        'data-role': 'm-point'
        includers : "#{point.get('includers')}"

  show_point_details_handler : (point_id) ->

    if @$el.is(':visible')
      is_paginated = @collection.information?
      point = @collection.get(point_id)        
      if !point? && is_paginated

        current_page = @collection.currentPage
        for page in [1..@collection.information.totalPages+1]
          @collection.goTo(page)
          point = @collection.get(point_id)   
          break if point?

      if point?
        @getViewByModel(point).show_point_details_handler()
      else if is_paginated
        @collection.goTo(current_page)


  @events : 
    'click [data-target="m-point-details"]' : 'navigate_point_details'
    'click [data-target="point-include"]' : 'include_point'
    'click [data-target="point-remove"]' : 'remove_point'

  events : @events

  navigate_point_details : (ev) ->
    point_id = $(ev.currentTarget).data('id')
    ConsiderIt.router.navigate(Routes.proposal_point_path(@proposal.long_id, point_id), {trigger: true})

  include_point : (ev) ->
    ev.stopPropagation()
    @trigger 'pointlistview:point_included', $(ev.currentTarget).data('id')

  remove_point : (ev) ->
    ev.stopPropagation()
    @trigger 'pointlistview:point_removed', $(ev.currentTarget).data('id')

class ConsiderIt.PaginatedPointListView extends ConsiderIt.PointListView

  @paging_template : _.template($('#tpl_pointlistpagination').html())

  initialize : (options) -> super

  render : () ->
    super
    @$el.find('.m-pointlist-empty, .m-pointlist-pagination').remove()

    @collection.info()
    
    @$el.append('<div class="m-pointlist-pagination">') if @collection.size() > 0 
    
    @repaginate()
    @listenTo @collection, 'reset', () => @repaginate()


    if @collection.information.totalRecords > 5 #TODO: don't hardcode number of pages
      @$el.addClass('m-point-list-has-pagination')
    else if @collection.information.totalRecords == 0
      @$el.append ConsiderIt.PointListView.empty_template()

  onAdd : (model) ->
    super
    @collection.pager()

  onRemove : (model) ->
    super
    @collection.pager()

  repaginate : ->
    @$el.find('.m-pointlist-pagination').html(ConsiderIt.PaginatedPointListView.paging_template({
      start_record : @collection.information.startRecord
      end_record : @collection.information.endRecord
      total_records : @collection.information.totalRecords
    })) 

  events : _.extend @events, {
    'click .m-pointlist-forward' : 'forward'
    'click .m-pointlist-backward' : 'backward' }

  forward : (ev) -> 
    @collection.nextPage()
    #@repaginate()

  backward : (ev) ->
    @collection.previousPage()
    #@repaginate()

class ConsiderIt.BrowsablePointListView extends ConsiderIt.PointListView
  @browsing_template : _.template($('#tpl_pointlistbrowse').html())
  @browsing_header_template : _.template( $('#tpl_pointlistbrowse_header').html() )
  @points_per : 3

  initialize : () ->
    super
    @browsing = false
    @selected = 'persuasiveness'

    @collection.setSort(@selected, 'desc')

  render : () ->
    super
    @collection.info()
    
    @is_pro = @$el.parent().is('.m-reasons-peer-points-pros')

    if _.size(@collection.origModels) > 0
      @$browse_el.remove() if @$browse_el?

      @$browse_el = $('<div class="m-pointlist-browse">')

      @$browse_el.html ConsiderIt.BrowsablePointListView.browsing_template({
        pros : @is_pro,
        cnt : _.size(@collection.origModels)
      })
      @$el.append(@$browse_el)

      @$browse_header_el.remove() if @$browse_header_el?
      @$browse_header_el = $('<div class="m-pointlist-browse-header">')

      @$browse_header_el.html ConsiderIt.BrowsablePointListView.browsing_header_template({
        pros : @is_pro
        selected : @selected
      })
      @$el.prepend(@$browse_header_el)
      
      @$browse_header_el.css('visibility', 'visible') if @browsing
  
  onAdd : (model) ->
    super
    @collection.pager()

  onRemove : (model) ->
    super
    @collection.pager()

  events : _.extend @events, {
    'click .m-pointlist-browse-toggle' : 'toggle_browse_ev'
    'click .m-pointlist-sort-option a' : 'sort_list'}

  sort_list : (ev) ->
    @$el.find('.m-pointlist-sort-option a').removeClass('selected')
    $(ev.target).addClass('selected')

    target = $(ev.target).data('target')
    @selected = target
    if target == '-divisiveness'
      @collection.setSort('divisiveness')
    else if target == 'popularity'
      @collection.setSort('appeal', 'desc')
    else if target == 'persuasiveness'
      @collection.setSort('persuasiveness', 'desc')
    else if target == 'created_at'
      @collection.setSort('created_at', 'desc')

    @collection.pager()
    @$browse_el.find('.m-pointlist-browse-toggle').text "Stop browsing"
    
  toggle_browse_ev : (ev) ->
    @toggle_browse(!@browsing)
    ev.stopPropagation()

  toggle_browse : (browse) ->

    parent_position = @$el.closest('.m-position')
    if browse
      @$el.addClass 'm-pointlist-browsing'
      @previous_margin = parent_position.css('margin-left')
      parent_position.css('margin-left' : if @is_pro then '550px' else '-550px')
      @collection.howManyPer(1000)
      @$browse_el.find('.m-pointlist-browse-toggle').text "Stop browsing"
      @$browse_header_el.css('visibility', 'visible')

      # when clicking outside of pointlist, close browsing
      $(document).on 'click.m-pointlist-browsing', (ev)  => 
        if $(ev.target).closest('.m-pointlist-sort-option').length == 0 && $(ev.target).closest('.m-pointlist-browsing')[0] != @$el[0] && $('.m-point-expanded, .l-dialog-detachable').length == 0
          @toggle_browse(false) 
          ev.stopPropagation()

      $(document).on 'keyup.m-pointlist-browsing', (ev) => @toggle_browse(false) if ev.keyCode == 27 && $('.m-point-expanded, .l-dialog-detachable').length == 0

    else
      @$el.removeClass 'm-pointlist-browsing'
      parent_position.css('margin-left' : @previous_margin)
      @collection.howManyPer(ConsiderIt.BrowsablePointListView.points_per)
      @$browse_header_el.css('visibility', 'hidden')
      $(document).off '.m-pointlist-browsing'
      @$el.off '.m-pointlist-browsing'
      window.ensure_el_in_view(@$el.find('.m-pointlist-browse-toggle'), .5, 100)


    @browsing = browse
