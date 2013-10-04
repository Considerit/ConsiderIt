@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Position extends App.Entities.Model
    name : 'position'
    defaults : 
      stance : 0
      user_id : -1

    urlRoot : ''
    included_points : []

    url : () ->
      if @attributes.proposal_id #avoid url if this is a new proposal
        Routes.proposal_position_path( @get('long_id'), @id) 

    initialize : (options) ->
      super
      #TODO: create HTML version of explanation, instead of overwriting old
      @attributes.explanation = htmlFormat(@attributes.explanation) if @attributes.explanation
      
      # @proposal = ConsiderIt.all_proposals.get @attributes.proposal_id
      @written_points = []
      @viewed_points = {}

    # subsume : (other_pos) ->
    #   params = 
    #     stance : if other_pos.get('stance') != 0 then other_pos.get('stance') else @get('stance')
    #     stance_bucket : other_pos.get('stance_bucket')

    #   explanation = other_pos.get('explanation')
    #   params.explanation = explanation if explanation? and explanation.length > 0

    #   @set params

    clear : ->
      super
      @written_points = []
      @viewed_points = {}

    setIncludedPoints : (points) ->
      @included_points = points

    getIncludedPoints : ->
      @included_points

    includePoint : (point) ->
      @included_points.push point.id

    removePoint : (point) ->
      @setIncludedPoints _.without(@included_points, point.id)

    addViewedPoint : (point) ->
      @viewed_points[point.id] = 1
      
    # relations

    getInclusions : ->
      new App.Entities.Points (App.request('point:get', p) for p in @inclusions())

    inclusions : ->
      if @get('point_inclusions') then $.parseJSON(@get('point_inclusions')) else []

    getProposal : ->
      if !@proposal
        @proposal = App.request 'proposal:get', @get('long_id')
      @proposal

    getUser : ->
      App.request 'user', @get('user_id')

    setUser : (user) ->
      @set 'user_id', user.id

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

    addPositions : (positions, position = null) ->
      @all_positions.add @all_positions.parse(positions), {merge: true}

      if position
        @all_positions.add position, {merge: true}

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

  App.vent.on 'positions:fetched', (positions, position = null) ->
    API.addPositions positions, position

  App.reqres.setHandler 'position:get', (position_id) ->
    API.getPosition position_id

  App.reqres.setHandler 'position:create', (attrs = {}) ->
    API.createPosition attrs

  App.reqres.setHandler 'positions:get', ->
    API.getPositions()

  App.reqres.setHandler 'positions:get:proposal', (model_id) ->
    API.getPositionsByProposal model_id

  App.reqres.setHandler 'positions:get:user', (model_id) ->
    API.getPositionsByUser model_id

