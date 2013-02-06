class ConsiderIt.ProposalView extends Backbone.View
  @template : _.template( $("#tpl_proposal").html() )
  tagName : 'li'

  initialize : (options) -> 
    #@state = 0
    @long_id = @model.get('long_id')
    @proposal = ConsiderIt.proposals[@long_id]
    @data_loaded = false

  render : () -> 

    @$el.html(
      ConsiderIt.ProposalView.template($.extend({}, this.model.attributes, {title : this.model.title()}))
    )
    #@state = 1
    this

  load_data : (callback, callback_params) ->
    $.get Routes.proposal_path(@long_id), (data) =>
      _.extend(@proposal, {
        points : {
          pros : _.map(data.points.pros, (pnt) -> new ConsiderIt.Point(pnt.point))
          cons : _.map(data.points.cons, (pnt) -> new ConsiderIt.Point(pnt.point))
          included_pros : new ConsiderIt.PointList()
          included_cons : new ConsiderIt.PointList()
          peer_pros : new ConsiderIt.PaginatedPointList()
          peer_cons : new ConsiderIt.PaginatedPointList()
          viewed_points : {}          
        }
        positions : _.map(data.positions, (pos) -> new ConsiderIt.Position(pos.position))
        position : new ConsiderIt.Position(data.position.position)
      })

      @proposal.positions.push(@proposal.position)

      # separating points out into peers and included
      for [source_points, source_included, dest_included, dest_peer] in [[@proposal.points.pros, data.points.included_pros, @proposal.points.included_pros, @proposal.points.peer_pros], [@proposal.points.cons, data.points.included_cons, @proposal.points.included_cons, @proposal.points.peer_cons]]
        indexed_inclusions = _.object( ([pnt.point.id, true] for pnt in source_included)  )
        peers = []
        included = []
        for pnt in source_points
          if pnt.id of indexed_inclusions
            included.push(pnt)
          else
            peers.push(pnt)

        dest_peer.reset(peers)
        dest_included.reset(included)

      @data_loaded = true    
      callback(this, callback_params)

  take_position : (me) ->

    if me.proposal.views.show_results?
      me.proposal.views.show_results.hide()

    me.$el.find('.top_points').fadeOut()

    if me.proposal.views.take_position?
      me.proposal.views.take_position.show()
    else
      me.proposal.views.take_position = new ConsiderIt.PositionView({ el : me.$el.find('.user_opinion'), proposal : me.proposal, model : me.proposal.position})
      me.proposal.views.take_position.render()  


  take_position_handler : () ->
    if !@data_loaded
      @load_data(@take_position)
    else
      @take_position(this)

    #@state = 2

  show_results : (me) ->
    if me.proposal.views.take_position?
      me.proposal.views.take_position.hide()
    
    me.$el.find('.top_points').fadeOut()

    if me.proposal.views.show_results?
      me.proposal.views.show_results.show()
    else
      me.proposal.views.show_results = new ConsiderIt.ResultsView({ el : me.$el.find('.aggregated_results'), proposal : me.proposal})
      me.proposal.views.show_results.render()

  show_results_handler : () ->
    if !@data_loaded
      @load_data(@show_results)
    else
      @show_results(this)

    #@state = 3


  # Point details are being handled here (messily) for the case when a user directly visits the point details page without
  # (e.g. if they followed a link to it). In that case, we need to create some context around it first.
  prepare_for_point_details : (me, params) ->
    me.show_results(me)
    results_view = me.proposal.views.show_results

    point = results_view.pointlists.pros.get(params.point_id)
    if point?
      pointview = results_view.views.pros.getViewByModel(point)
    else
      point = results_view.pointlists.cons.get(params.point_id)
      if point?
        pointview = results_view.views.cons.getViewByModel(point)
    pointview.show_point_details_handler()


  show_point_details_handler : (point_id) ->
    if !@data_loaded
      @load_data(@prepare_for_point_details, {point_id : point_id})
    # if data is already loaded, then the PointListView is already properly handling this






