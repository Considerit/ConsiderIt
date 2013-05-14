class ConsiderIt.ProposalList extends Backbone.Paginator.clientPager
  model: ConsiderIt.Proposal

  paginator_ui: 
    firstPage: 1
    currentPage: 1
    perPage: 200

  # comparator : (proposal) ->
  #   -proposal.get("activity")

  initialize: (options) -> 
    super

    @on 'add', (model) =>
      model.long_id = model.get('long_id')
      model.set('description', htmlFormat(model.attributes.description))


    if options? && options.perPage? 
      @perPage = options.perPage    
