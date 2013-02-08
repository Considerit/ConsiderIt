class ConsiderIt.ProposalList extends Backbone.Collection
  model: ConsiderIt.Proposal

  comparator : (proposal) ->
    -proposal.get("activity")
