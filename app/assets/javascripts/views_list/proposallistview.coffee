class ConsiderIt.ProposalListView extends Backbone.CollectionView
  @proposals_header_template = _.template($('#tpl_proposal_list_header').html())

  itemView : ConsiderIt.ProposalView
  @childClass : 'm-proposal'
  listSelector : '.m-proposal-list'

  initialize : (options) -> 
    @listenTo ConsiderIt.app, 'proposal:deleted', (proposal) => @delete_proposal(proposal)
    
    super
  
  render : -> 
    super
    @render_header()


  #TODO: do this when login as admin
  render_header : ->

    $heading_el = ConsiderIt.ProposalListView.proposals_header_template({is_admin : ConsiderIt.roles.is_admin})

    @$el.find('.m-proposals-list-header').remove()
      
    @$el.prepend($heading_el)


  # Returns an instance of the view class
  getItemView: (proposal)->
    id = proposal.get('long_id')

    if id of ConsiderIt.proposals
      delete ConsiderIt.proposals[id].view if id of ConsiderIt.proposals
    else
      ConsiderIt.proposals[id] = 
        top_con : null
        top_pro : null
        points : null
        positions : null
        view : null
        views : {}
        model : proposal

      ConsiderIt.proposals_by_id[proposal.id] = ConsiderIt.proposals[id]


    ConsiderIt.proposals[id].view = new @itemView
      model: proposal
      collection: @collection
      attributes : 
        'data-id': "#{proposal.id}"
        'data-role': 'm-proposal'
        id : "#{id}"
        class : "#{ConsiderIt.ProposalListView.childClass}"

    return ConsiderIt.proposals[id].view

  #handlers
  events :
    'click .m-new-proposal-submit' : 'create_new_proposal'
    
  create_new_proposal : (ev) ->

    attrs = 
      name : 'Should we ... ?'
      description : "We're thinking about ..."

    new_proposal = @collection.create attrs, {
      wait: true
      at: 0
      success: => 
        new_view = @getViewByModel new_proposal
        new_view.toggle()

    }

  delete_proposal : (proposal) ->
    ConsiderIt.router.navigate(Routes.root_path(), {trigger: true})
    delete ConsiderIt.proposals_by_id[proposal.id]
    delete ConsiderIt.proposals[proposal.long_id]
    @collection.remove proposal
