class ConsiderIt.Point extends Backbone.Model
  defaults: { 
  }
  name: 'point'

  initialize : () ->
    super
    @attributes.nutshell = htmlFormat(@attributes.nutshell)
    @attributes.text = htmlFormat(@attributes.text)

  url : () ->
    if @id
      Routes.proposal_point_path( ConsiderIt.proposals_by_id[@get('proposal_id')].model.get('long_id'), @id) 
    else
      Routes.proposal_points_path( ConsiderIt.proposals_by_id[@get('proposal_id')].model.get('long_id') ) 


  is_manager : () -> false

  has_details : () -> attributes.text? && attributes.text.length > 0

  adjusted_nutshell : () -> 
    nutshell = this.get('nutshell')
    if nutshell.length > 140
      nutshell[0..140]
    else if nutshell.length > 0
      nutshell
    else if this.get('text').length > 137 
      this.get('text')[0..137] 
    else
      this.get('text')
