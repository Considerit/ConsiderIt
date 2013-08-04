class ConsiderIt.Proposal extends Backbone.Model
  defaults : () => { participants : '[]'}
  name: 'proposal'
  @description_detail_fields : ['long_description', 'additional_details']

  initialize : (options, top_pro, top_con) ->
    super options
    #@attributes.description = htmlFormat(@attributes.description)

    @data_loaded = false

    @pros = @cons = @included_pros = @included_cons = @peer_pros = @peer_cons = @positions = @position = null

    @top_pro = if top_pro? && 'proposal_id' of top_pro then top_pro else null
    @top_con = if top_con? && 'proposal_id' of top_con then top_con else null

    @long_id = @attributes.long_id
    #@position = new ConsiderIt.Position({})

  url : () ->
    if @id
      Routes.proposal_path( @attributes.long_id ) 
    else
      Routes.proposals_path( )

  set_data : (data) -> 
    @pros =  new Backbone.Collection( _.map(data.points.pros||[], (pnt) -> new ConsiderIt.Point(pnt.point)) )
    @cons = new Backbone.Collection( _.map(data.points.cons||[], (pnt) -> new ConsiderIt.Point(pnt.point)) )
    @included_pros = new ConsiderIt.PointList()
    @included_cons = new ConsiderIt.PointList()
    @peer_pros = new ConsiderIt.PaginatedPointList()
    @peer_cons = new ConsiderIt.PaginatedPointList()

    @positions = _.object(_.map(data.positions||[], (pos) -> [pos.position.user_id, new ConsiderIt.Position(pos.position)]))
    @position = new ConsiderIt.Position(data.position.position)
    @positions[@position.get('user_id')] = @position

    @top_pro = @pros.get( @get('top_pro') ).attributes if !@top_pro && @get('top_pro')
    @top_con = @cons.get( @get('top_con') ).attributes if !@top_con && @get('top_con')

    # separating points out into peers and included
    for [source_points, source_included, dest_included, dest_peer] in [[@pros, data.points.included_pros||[], @included_pros, @peer_pros], [@cons, data.points.included_cons||[], @included_cons, @peer_cons]]
      indexed_inclusions = _.object( ([pnt.point.id, true] for pnt in source_included)  )
      peers = []
      included = []
      source_points.each (pnt) =>
        if pnt.id of indexed_inclusions
          included.push(pnt)
        else
          peers.push(pnt)

      dest_peer.reset(peers)
      dest_included.reset(included)

    @data_loaded = true
    @trigger 'proposal:data_loaded'

  update_anonymous_point : (point_id, is_pro) ->
    points = if is_pro then @pros else @cons
    points.each (pm) => pm.set('user_id', ConsiderIt.request('user:current').id) if pm.id == point_id

  title : (max_len = 140) ->
    if @get('name') && @get('name').length > 0
      my_title = @get('name')
    else if @get('description')
      my_title = @get('description')
    else
      throw 'Name and description nil'
    
    if my_title.length > max_len
      "#{my_title[0..max_len]}..."
    else
      my_title

  updated_position : (position) ->
    user_id = @position.get('user_id')
    @participant_list.push user_id if position.get('published') && !@user_participated(user_id)

  description_detail_fields : ->
    [ ['long_description', 'Long Description', $.trim(htmlFormat(@attributes.long_description))], 
      ['additional_details', 'Fiscal Impact Statement', $.trim(htmlFormat(@attributes.additional_details))] ]

  user_participated : (user_id) -> user_id in @participants()

  participants : ->
    if !@participant_list?
      @participant_list = $.parseJSON(@attributes.participants) || []
    @participant_list

  has_participants : -> 
    return @participants().length > 0   
