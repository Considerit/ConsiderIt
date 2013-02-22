class ConsiderIt.ProposalListView extends Backbone.CollectionView

  itemView : ConsiderIt.ProposalView
  @childClass : 'm-proposal'
  listSelector : '.m-proposal-list'

  initialize : (options) -> 
    super
  
  render : () -> 
    super

  # Returns an instance of the view class
  getItemView: (proposal)->
    id = proposal.get('long_id')
    delete ConsiderIt.proposals[id].view
    ConsiderIt.proposals[id].view = new @itemView
      model: proposal
      collection: @collection
      attributes : 
        'data-id': "#{proposal.cid}"
        id : "#{id}"
        class : "#{ConsiderIt.ProposalListView.childClass} l-content-wrap"
    
    return ConsiderIt.proposals[id].view

  #handlers
  events : {}

