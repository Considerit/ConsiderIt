@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Position extends App.Entities.Model
    name : 'position'
    defaults : 
      stance : 0
      user_id : -1

    urlRoot : ''

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

    subsume : (other_pos) ->
      params = 
        stance : if other_pos.get('stance') != 0 then other_pos.get('stance') else @get('stance')
        stance_bucket : other_pos.get('stance_bucket')

      explanation = other_pos.get('explanation')
      params.explanation = explanation if explanation? and explanation.length > 0

      @set params

    clear : ->
      super
      @written_points = []
      @viewed_points = {}

    setIncludedPoints : (points) ->
      @included_points = points

    getIncludedPoints : ->
      if !@included_points
        throw 'Included points never created'
      @included_points

    includePoint : (point) ->
      @included_points.push point.id

    removePoint : (point) ->
      @setIncludedPoints _.without @included_points, [point.id]

      
    # relations

    inclusions : ->
      if @get('point_inclusions') then $.parseJSON(@get('point_inclusions')) else []

    getProposal : ->
      if !@proposal
        @proposal = App.request 'proposal:get', @get('long_id')
      @proposal

    getUser : ->
      if !@user 
        @user = App.request 'user', @get('user_id')
      @user


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

    addPositions : (positions, position = null) ->
      @all_positions.add @all_positions.parse(positions), {merge: true}

      if position
        @all_positions.add position, {merge: true}

    getPosition : (position_id) ->
      @all_positions.get position_id

    getPositionsByProposal : (proposal_id) ->
      new Entities.Positions @all_positions.where({proposal_id: proposal_id})

    getPositionsByUser : (user_id) ->
      new Entities.Positions @all_positions.where({user_id: user_id})


  App.vent.on 'positions:fetched', (positions, position = null) ->
    API.addPositions positions, position

  App.reqres.setHandler 'position:get', (position_id) ->
    API.getPosition position_id

  App.reqres.setHandler 'positions:get:proposal', (model_id) ->
    API.getPositionsByProposal model_id

  App.reqres.setHandler 'positions:get:user', (model_id) ->
    API.getPositionsByUser model_id
