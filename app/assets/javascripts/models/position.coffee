class ConsiderIt.Position extends Backbone.Model
  defaults: 
    stance : 0
    user_id : -1

  name: 'position'


  url : () ->
    Routes.proposal_position_path( ConsiderIt.proposals_by_id[@get('proposal_id')].model.get('long_id'), @id) 

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