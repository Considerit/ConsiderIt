class ConsiderIt.Position extends Backbone.Model
  defaults: 
    stance : 0
    user_id : -1

  name: 'position'

  initialize : (options, proposal) ->
    super
    @attributes.explanation = htmlFormat(@attributes.explanation) if @attributes.explanation
    @proposal = proposal
    @written_points = {}
    @viewed_points = {}

  url : () ->
    if @attributes.proposal_id #avoid url if this is a new proposal
      Routes.proposal_position_path( @proposal.long_id, @id) 

  clear : ->
    super
    @written_points = {}
    @viewed_points = {}

  @stance_name_for_bar : (d) ->
    switch parseInt(d)
      when 0 then "adamantly oppose"
      when 1 then "strongly oppose"
      when 2 then "lean oppose"
      when 3 then "are neutral"
      when 4 then "lean support"
      when 5 then "strongly support"
      when 6 then "fervently support"

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





