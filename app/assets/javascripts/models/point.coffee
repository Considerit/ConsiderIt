class ConsiderIt.Point extends Backbone.Model
  defaults: { }
  name: 'point'

  initialize : ->
    super
    @proposal = ConsiderIt.app.proposals.get @attributes.proposal_id
    @attributes.nutshell = htmlFormat(@attributes.nutshell)
    @attributes.text = htmlFormat(@attributes.text)

  url : () ->
    if @id
      Routes.proposal_point_path( @proposal.long_id, @id) 
    else
      Routes.proposal_points_path( @proposal.long_id ) 


  #is_manager : () -> false

  has_details : -> attributes.text? && attributes.text.length > 0

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

  update_assessable_data : (data) ->
    @assessment = data.assessment
    @claims = []
    @num_assessment_requests = data.num_assessment_requests
    @already_requested_assessment = data.already_requested_assessment

    if data.claims
      for d in data.claims 
        d.claim.result = htmlFormat(d.claim.result)

        @claims.push(d.claim)

