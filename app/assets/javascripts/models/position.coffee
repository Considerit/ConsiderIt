class ConsiderIt.Position extends Backbone.Model
  defaults : () => { "stance" : 0, "user_id" : -1}

  name: 'position'

  initialize : (options) ->
    super
    @attributes.explanation = htmlFormat(@attributes.explanation) if @attributes.explanation
    @proposal = ConsiderIt.all_proposals.get @attributes.proposal_id
    @written_points = []
    @viewed_points = {}

  url : () ->
    if @attributes.proposal_id #avoid url if this is a new proposal
      Routes.proposal_position_path( @proposal.long_id, @id) 

  clear : ->
    super
    @written_points = []
    @viewed_points = {}

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

  subsume : (other_pos) ->
    params = 
      stance : if other_pos.get('stance') != 0 then other_pos.get('stance') else @get('stance')
      stance_bucket : other_pos.get('stance_bucket')

    explanation = other_pos.get('explanation')
    params.explanation = explanation if explanation? and explanation.length > 0

    @set params

  inclusions : ->
    if @get('point_inclusions') then $.parseJSON(@get('point_inclusions')) else []




