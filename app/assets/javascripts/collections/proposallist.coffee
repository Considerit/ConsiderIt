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

    if options? && options.perPage? 
      @perPage = options.perPage    
