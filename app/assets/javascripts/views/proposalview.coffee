class ConsiderIt.ProposalView extends Backbone.View
  @template : _.template( $("#tpl_proposal").html() )
  tagName : 'li'

  initialize : (options) -> 
    #@state = 0
    @long_id = @model.get('long_id')
    @proposal = ConsiderIt.proposals[@long_id]
    @data_loaded = false

  render : () -> 

    @$el.html ConsiderIt.ProposalView.template($.extend({}, @model.attributes, {
        title : this.model.title() 
        top_pro : @proposal.top_pro 
        top_con : @proposal.top_con
        tile_size : @fit_participants($.parseJSON(@model.get('participants')).length)
      }))

    this


  set_data : (data) =>
    _.extend(@proposal, {
      points : {
        pros : _.map(data.points.pros, (pnt) -> new ConsiderIt.Point(pnt.point))
        cons : _.map(data.points.cons, (pnt) -> new ConsiderIt.Point(pnt.point))
        included_pros : new ConsiderIt.PointList()
        included_cons : new ConsiderIt.PointList()
        peer_pros : new ConsiderIt.PaginatedPointList()
        peer_cons : new ConsiderIt.PaginatedPointList()
        viewed_points : {}    
        written_points : []
      }
      positions : _.object(_.map(data.positions, (pos) -> [pos.position.user_id, new ConsiderIt.Position(pos.position)]))
      position : new ConsiderIt.Position(data.position.position)
    })

    @proposal.positions[@proposal.position.user_id] = @proposal.position

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
    @listenTo ConsiderIt.app, 'user:signin', @post_signin
    @listenTo ConsiderIt.app, 'user:signout', @post_signout
    @trigger 'proposal:data_loaded'


  load_data : (callback, callback_params) ->
    @once 'proposal:data_loaded', => callback(this, callback_params)
    if ConsiderIt.current_proposal && ConsiderIt.current_proposal.long_id == @long_id
      @set_data(ConsiderIt.current_proposal.data)
    else
      $.get Routes.proposal_path(@long_id), @set_data


  merge_existing_position_into_current : (existing_position) ->
    existing_position.subsume(@proposal.position)
    @proposal.position.set(existing_position.attributes)
    @proposal.positions[ConsiderIt.current_user.id] = @proposal.position
    delete @proposal.positions[-1]

    # transfer already included points from existing_position into the included lists
    _.each $.parseJSON(existing_position.get('point_inclusions')), (pnt_id) =>
      if (model = @proposal.points.peer_pros.remove_from_all(pnt_id))?
        @proposal.points.included_pros.add model
      else if (model = @proposal.points.peer_cons.remove_from_all(pnt_id))?
        @proposal.points.included_cons.add model

  post_signin : () ->
    point.set('user_id', ConsiderIt.current_user.id) for point in @proposal.points.written_points
    existing_position = @proposal.positions[ConsiderIt.current_user.id]
    if existing_position?
      @merge_existing_position_into_current(existing_position)
    @trigger 'proposal:handled_signin'


  post_signout : () -> 
    _.each @proposal.points.written_points, (pnt) ->
      if pnt.get('is_pro') @proposal.points.included_pros.remove(pnt) else @proposal.points.included_cons.remove(pnt)

    @proposal.position.clear()
    @proposal.points.written_points = {}
    @proposal.points.viewed_points = {}
    @data_loaded = false
    @close()

  take_position : (me) ->
    $('html, body').animate {scrollTop: me.$el.offset().top - 50 }, 800

    _.each me.proposal.views, (vw) -> 
      delete vw.remove()
    me.proposal.views = {}

    # if me.proposal.views.show_results?
    #   me.proposal.views.show_results.remove() 
    # if me.proposal
      #delete me.proposal.views.show_results

    me.$el.find('.top_points').fadeOut()

    el = $('<div class="user_opinion">').insertAfter(me.$el.find('.question'))
    me.proposal.views.take_position = new ConsiderIt.PositionView
      el : el
      proposal : me.proposal
      model : me.proposal.position
      parent : me
    
    me.proposal.views.take_position.render()

    $('html, body').animate {scrollTop: me.$el.offset().top - 50 }, 200



  show_results : (me) ->
    $('html, body').animate {scrollTop: me.$el.offset().top - 50 }, 800

    _.each me.proposal.views, (vw) -> 
      delete vw.remove()
    me.proposal.views = {}

    # if me.proposal.views.take_position?
    #   me.proposal.views.take_position.remove() 
    #   delete me.proposal.views.take_position

    me.$el.find('.top_points').fadeOut()
    el = $('<div class="aggregated_results">').insertAfter(me.$el.find('.question'))

      
    me.proposal.views.show_results = new ConsiderIt.ResultsView
      el : el
      proposal : me.proposal

    me.proposal.views.show_results.render()

    $('html, body').animate {scrollTop: me.$el.offset().top - 50 }, 200


  take_position_handler : () ->
    if @data_loaded
      @take_position(this)
    else
      @load_data(@take_position)


  show_results_handler : () ->
    if @data_loaded
      @show_results(this)
    else
      @load_data(@show_results)


    #@state = 3

  close : () ->
    _.each @proposal.views, (vw) -> 
      delete vw.remove()
    @proposal.views = {}
    @$el.find('.top_points').fadeIn()


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

    pointview.show_point_details_handler() if pointview?

  show_point_details_handler : (point_id) ->
    if !@data_loaded
      @load_data(@prepare_for_point_details, {point_id : point_id})
    # if data is already loaded, then the PointListView is already properly handling this


  fit_participants : (num_participants) ->
    width = 150
    height = 250
    Math.min 50, ConsiderIt.utils.get_tile_size(width, height, num_participants)

    #$participants
    #  .css({'width': tile_size, 'height': tile_size})



