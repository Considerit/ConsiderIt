@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Position extends App.Entities.Model
    name : 'position'
    defaults : 
      stance : 0
      user_id : -1

    urlRoot : ''
    written_points : []
    viewed_points : {}

    url : () ->
      if @attributes.proposal_id #avoid url if this is a new proposal

        if @id
          Routes.proposal_position_path @get('long_id'), @id
        else
          Routes.proposal_positions_path @get('long_id')

    initialize : (options) ->
      super
      #TODO: create HTML version of explanation, instead of overwriting old
      @attributes.explanation = htmlFormat(@attributes.explanation) if @attributes.explanation
      
      # @proposal = ConsiderIt.all_proposals.get @attributes.proposal_id


    subsume : (other_pos) ->
      params = 
        stance : if other_pos.get('stance') != 0 then other_pos.get('stance') else @get('stance')
        stance_bucket : if other_pos.get('stance') != 0 then other_pos.get('stance_bucket') else @get('stance_bucket')

      explanation = other_pos.get('explanation')
      params.explanation = explanation if explanation? and explanation.length > 0

      @set params

      @viewed_points = _.union @viewed_points, other_pos.viewed_points
      @written_points = _.union @written_points, other_pos.written_points
      @included_points = _.union @getIncludedPoints(), other_pos.getIncludedPoints()

    clear : ->
      super
      @written_points = []
      @viewed_points = {}

    getIncludedPoints : ->
      if !@included_points
        @included_points = if @get('point_inclusions') then $.parseJSON(@get('point_inclusions')) else []

      @included_points

    includePoint : (point) ->
      included_points = @getIncludedPoints()
      included_points.push point.id

    removePoint : (point) ->
      if !@included_points
        throw 'Removing point without having defined included points first!'
      @included_points = _.without(@included_points, point.id)

    addViewedPoint : (point_id) ->
      @viewed_points[point_id] = 1
      

    # relations

    getInclusions : ->
      new App.Entities.Points (App.request('point:get', p) for p in @getIncludedPoints())

    getProposal : ->
      if !@proposal
        @proposal = App.request 'proposal:get', @get('long_id')
      @proposal

    getUser : ->
      App.request 'user', @get('user_id')

    setUser : (user) ->
      @set 'user_id', user.id
      if @written_points
        _.each @written_points, (pnt) =>
          pnt.set 'user_id', user.id      

    stanceLabel : ->
      Entities.Position.stance_name_adverb @get('stance_bucket')

    @stance_name_for_bar : (d) ->
      switch parseInt(d)
        when 0 then "fully oppose"
        when 1 then "strongly oppose"
        when 2 then "lean oppose"
        when 3 then "are neutral"
        when 4 then "lean support"
        when 5 then "strongly support"
        when 6 then "fully support"

    @stance_name_adverb : (d) ->
      switch parseInt(d)
        when 0 then "fully opposes"
        when 1 then "strongly opposes"
        when 2 then "leans oppose on"
        when 3 then "is neutral about"
        when 4 then "leans support on"
        when 5 then "strongly supports"
        when 6 then "fully supports"

    @stance_name : (d) ->
      switch parseInt(d)
        when 0 then "strong opposers"
        when 1 then "opposers"
        when 2 then "mild opposers"
        when 3 then "neutral parties"
        when 4 then "mild supporters"
        when 5 then "supporters"
        when 6 then "strong supporters"

  class Entities.Positions extends App.Entities.Collection
    model : Entities.Position

  API = 
    all_positions : new Entities.Positions()

    getPosition : (position_id) ->
      @all_positions.get position_id

    createPosition : (position_attrs = {}) ->
      position = new Entities.Position position_attrs
      @all_positions.add position
      position

    syncPosition : (position, params = {}) -> 
      console.log position
      params = _.extend params, 
        included_points : position.getIncludedPoints()
        viewed_points : _.keys(position.viewed_points)
        position : 
          position.attributes

      method = if position.id then 'update' else 'create'

      xhr = Backbone.sync method, position,
        data : JSON.stringify params
        contentType : 'application/json'

        success : (data) =>
          proposal = position.getProposal()
          position.set data.position.position

          App.vent.trigger 'points:fetched', (p.point for p in data.updated_points)
          proposal.set(data.proposal) if 'proposal' of data

          App.vent.trigger('position:subsumed', data.subsumed_position.position) if 'subsumed_position' of data && data.subsumed_position && data.subsumed_position.id != position.id
          proposal.newPositionSaved position

          #TODO: make sure points getting updated properly in all containers

          #TODO: check to make sure this case of newfound activity is handled
          # if @$el.data('activity') == 'proposal-no-activity' && @model.has_participants()
          #   @$el.attr('data-activity', 'proposal-has-activity')

          position.trigger 'position:synced'

        failure : (data) => @trigger 'position:sync:failed'

      App.execute 'show:loading',
        loading:
          entities : xhr
          xhr: true


    addPositions : (positions) -> #, position = null) ->
      positions = @all_positions.parse(positions)
      @all_positions.add positions, {merge: true}
      # if position
      #   @all_positions.add position, {merge: true}

    getPositionForProposalForCurrentUser : (proposal_id, create_if_not_found = true) ->
      current_user = App.request 'user:current'
      params = 
        proposal_id: proposal_id
        user_id: current_user.id

      position = @all_positions.findWhere
        proposal_id: proposal_id
        user_id: current_user.id

      if !position && create_if_not_found

        position = new Entities.Position # todo: does this work when someone logs in after position created?
          user_id : current_user.id #todo: make sure this doesn't get shown in results
          published : false
          proposal_id : proposal_id
          long_id: App.request('proposal:get:id', proposal_id).get('long_id')

        @all_positions.add position

      position


    getPositionsByProposal : (proposal_id) ->
      new Entities.Positions @all_positions.where({proposal_id: proposal_id, published : true})

    getPositionsByUser : (user_id) ->
      new Entities.Positions @all_positions.where({user_id: user_id})

    getPositions : ->
      @all_positions

    positionSubsumed : (position_data) ->
      position = @all_positions.get position_data.id
      #@all_positions.remove position
      position.trigger 'destroy', position, position.collection

  App.vent.on 'position:subsumed', (position_data) ->
    API.positionSubsumed position_data

  App.vent.on 'positions:fetched', (positions) -> #, position = null) ->
    API.addPositions positions #, position

  App.reqres.setHandler 'position:get', (position_id) ->
    API.getPosition position_id

  App.reqres.setHandler 'position:create', (attrs = {}) ->
    API.createPosition attrs

  App.reqres.setHandler 'position:sync', (position, params) ->
    API.syncPosition position, params

  App.reqres.setHandler 'positions:get', ->
    API.getPositions()

  App.reqres.setHandler 'positions:get:proposal', (model_id) ->
    API.getPositionsByProposal model_id

  App.reqres.setHandler 'positions:get:user', (model_id) ->
    API.getPositionsByUser model_id

  App.reqres.setHandler 'position:current_user:proposal', (proposal_id, create_if_not_found = true) ->
    API.getPositionForProposalForCurrentUser proposal_id, create_if_not_found


  App.addInitializer ->

    if ConsiderIt.positions && _.size(ConsiderIt.positions) > 0
      App.vent.trigger 'positions:fetched', ConsiderIt.positions
      ConsiderIt.positions = null


