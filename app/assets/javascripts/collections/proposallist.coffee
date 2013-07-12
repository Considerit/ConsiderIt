class ConsiderIt.ProposalList extends Backbone.Paginator.clientPager
  model: ConsiderIt.Proposal

  paginator_ui: 
    firstPage: 1
    currentPage: 1
    perPage: 5

  initialize: (options) -> 
    super

    ####################################
    # patch for Backbone.paginator
    @origModels = if @models then @models.slice() else []
    ####################################

    @on 'add', (model) =>
      model.long_id = model.get('long_id')
      model.set('description', htmlFormat(model.attributes.description))

    @listenTo ConsiderIt.router, 'user:signin', =>
    @listenTo ConsiderIt.router, 'user:signout', => 
      @purge_inaccessible()



  add_proposals : (proposals_data) ->
    proposals = []

    for prop in proposals_data

      if !(@get(prop.model.proposal.id)?)
        top_pro = if prop.top_pro then prop.top_pro.point else null
        top_con = if prop.top_con then prop.top_con.point else null
        proposal = new ConsiderIt.Proposal(prop.model.proposal, top_pro, top_con)
        proposals.push(proposal)

    @add proposals
    ConsiderIt.all_proposals.add proposals if ConsiderIt.app? && ConsiderIt.all_proposals != @
    # Watchout! sometimes the collection won't keep the same proposal object, so ConsiderIt.all_proposals might be out of sync with @collection

  add_proposal : (proposal_data) ->  
    current_proposal = @get proposal_data.proposal.id

    if !current_proposal
      current_proposal = new ConsiderIt.Proposal(proposal_data.proposal)
      @add current_proposal

    current_proposal.set_data(proposal_data)

  purge_inaccessible : -> @remove @filter( (p) -> p.get('publicity') < 2 || !p.get('published'))