class ConsiderIt.ProposalListView extends Backbone.CollectionView
  @proposals_header_template = _.template($('#tpl_proposal_list_header').html())

  itemView : ConsiderIt.ProposalView
  @childClass : 'm-proposal'
  listSelector : '.m-proposal-list'

  initialize : (options) -> 
    @sort_selected = 'activity'
    @filter_selected = 'all'
    super
    @listenTo ConsiderIt.app, 'proposal:deleted', (proposal) => @delete_proposal(proposal)
    @sort_proposals()

  render : -> 
    super
    @render_header()


  #TODO: do this when login as admin
  render_header : ->

    $heading_el = ConsiderIt.ProposalListView.proposals_header_template({
      is_admin : ConsiderIt.roles.is_admin
      selected_sort : @sort_selected
      selected_filter : @filter_selected
      })

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
        points :
          pros : []
          cons : []
          included_pros : new ConsiderIt.PointList()
          included_cons : new ConsiderIt.PointList()
          peer_pros : new ConsiderIt.PaginatedPointList()
          peer_cons : new ConsiderIt.PaginatedPointList()
          viewed_points : {}    
          written_points : []        

        positions : []
        position : new ConsiderIt.Position({}) #TODO: make sure initial position submitted & handled by server when submitting new proposal
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
        'data-activity': if ConsiderIt.proposals[id].has_participants then 'proposal-has-activity' else 'proposal-no-activity'

    return ConsiderIt.proposals[id].view

  #handlers
  events :
    'click .m-new-proposal-submit' : 'create_new_proposal'
    'click .m-proposallist-sort' : 'sort_proposals_to'
    'click .m-proposallist-filter' : 'filter_proposals_to'

  sort_proposals_to : (ev) ->   
    @sort_selected = $(ev.target).data('target')
    @sort_proposals()

  sort_proposals : ->

    @collection.setSort( @sort_selected, 'desc')

    @render_header()
    @collection.updateList()


  filter_proposals_to : (ev) ->
    @filter_selected = $(ev.target).data('target')
    @filter_proposals()

  filter_proposals : ->

    if @filter_selected == 'all'
      @collection.setFieldFilter()
    else if @filter_selected == '-active'
      @collection.setFieldFilter [{
        field : 'active'
        type : 'equalTo' 
        value : false
      }]
    else if @filter_selected == 'active'
      @collection.setFieldFilter [{
        field : 'active'
        type : 'equalTo' 
        value : true
      }]    

    @render_header()
    @collection.updateList()

  create_new_proposal : (ev) ->
    attrs = 
      name : 'Should we ... ?'
      description : "We're thinking about ..."

    new_proposal = @collection.create attrs, {
      wait: true
      at: 0
      success: => 
        ConsiderIt.proposals_by_id[new_proposal.id]

        new_view = @getViewByModel new_proposal
        new_view.$el.find('.m-proposal-introduction').trigger('click')
        #new_view.transition_expanded(1)

    }

  delete_proposal : (proposal) ->
    ConsiderIt.router.navigate(Routes.root_path(), {trigger: true})
    delete ConsiderIt.proposals_by_id[proposal.id]
    delete ConsiderIt.proposals[proposal.long_id]
    @collection.remove proposal
