class ConsiderIt.PointListView extends Backbone.CollectionView

  @itemView : ConsiderIt.PointView
  @childClass : 'm-point'

  listSelector : '.m-point-list'


  initialize : (options) ->
    super
    @location = options.location
    @proposal = options.proposal
    _.bindAll this
    ConsiderIt.router.on('route:PointDetails', @show_point_details_handler)

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

  show_point_details_handler : (long_id, point_id) ->
    if @$el.is(':visible') && @proposal.long_id == long_id
      point = @collection.get(point_id)
      if point?
        @getViewByModel(point).show_point_details_handler()


class ConsiderIt.PaginatedPointListView extends ConsiderIt.PointListView

  @paging_template : _.template($('#tpl_pointlistpagination').html())

  initialize : (options) ->
    super

  render : () ->
    super

    @collection.info()
    if @$el.find('.m-pointlist-pagination').length == 0 then @$el.append('<div class="m-pointlist-pagination">')

    @repaginate()
    @listenTo @collection, 'reset', () => @repaginate()

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

  events : 
    'click .m-pointlist-forward' : 'forward'
    'click .m-pointlist-backward' : 'backward'

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

  events : 
    'click .m-pointlist-browse-toggle' : 'toggle_browse_ev'
    'click .m-pointlist-sort-option a' : 'sort_list'

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

  toggle_browse_ev : (ev) ->
    @toggle_browse(!@browsing)

  toggle_browse : (browse) ->
    parent_position = @$el.closest('.m-position')
    if browse
      @$el.addClass 'm-pointlist-browsing'
      @previous_margin = parent_position.css('margin-left')
      parent_position.css('margin-left' : if @is_pro then '550px' else '-550px')
      @collection.howManyPer(1000)
      @$browse_el.find('.m-pointlist-browse-toggle').text "Stop browsing"
      @$browse_header_el.css('visibility', 'visible')
    else
      @$el.removeClass 'm-pointlist-browsing'
      parent_position.css('margin-left' : @previous_margin)
      @collection.howManyPer(ConsiderIt.BrowsablePointListView.points_per)
      @$browse_header_el.css('visibility', 'hidden')

    @browsing = browse

