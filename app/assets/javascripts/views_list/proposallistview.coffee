class ConsiderIt.ProposalListView extends Backbone.CollectionView

  itemView : ConsiderIt.ProposalView
  @childClass : 'm-proposal'
  listSelector : '.m-proposal-list'

  @new_proposal_template = _.template($('#tpl_new_proposal').html())

  initialize : (options) -> 
    @listenTo ConsiderIt.app, 'proposal:deleted', (proposal) => @delete_proposal(proposal)
    
    super
  
  render : -> 
    super
    @render_new_proposal()

  #TODO: do this when login as admin
  render_new_proposal : ->
    if ConsiderIt.roles.is_admin
      @$el.find('.m-proposals-new').remove()
      @$new_proposal = $('<div class="m-proposals-new l-content-wrap">')
        .html ConsiderIt.ProposalListView.new_proposal_template( {  })
      
      @$new_proposal.find('.m-proposal-description-body').autoResize()

      @$new_proposal.find('[placeholder]').simplePlaceholder()

      @$el.prepend(@$new_proposal)


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
        'data-id': "#{proposal.cid}"
        id : "#{id}"
        class : "#{ConsiderIt.ProposalListView.childClass}"
    
    return ConsiderIt.proposals[id].view

  #handlers
  events :
    'click .m-new-proposal-submit' : 'create_new_proposal'
    
  create_new_proposal : (ev) ->
    @$new_proposal

    attrs = 
      name : @$new_proposal.find('.m-proposal-name').val()
      description : @$new_proposal.find('.m-proposal-description-body').val()
      active : @$new_proposal.find('.m-proposal-active').val()
    @cancel_new_proposal()

    new_proposal = @collection.create attrs, {wait: true, at: 0}

  cancel_new_proposal : ->
    @$new_proposal.find('input[type="text"], textarea').val('')


  delete_proposal : (proposal) ->
    ConsiderIt.router.navigate(Routes.root_path(), {trigger: true})
    delete ConsiderIt.proposals_by_id[proposal.id]
    delete ConsiderIt.proposals[proposal.long_id]
    @collection.remove proposal
