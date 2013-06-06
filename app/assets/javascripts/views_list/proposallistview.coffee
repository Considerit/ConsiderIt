class ConsiderIt.ProposalListView extends Backbone.CollectionView
  @proposals_header_template = _.template($('#tpl_proposal_list_header').html())
  @proposals_create_template = _.template($('#tpl_proposal_list_new_conversation').html())

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
    # @undelegateEvents()
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

    if ConsiderIt.roles.is_admin && !@$create_el?
      @$create_el = ConsiderIt.ProposalListView.proposals_create_template()
      @$el.prepend(@$create_el)


  # Returns an instance of the view class
  getItemView: (proposal)->
    id = proposal.long_id

    new @itemView
      model: proposal
      collection: @collection
      attributes : 
        'data-id': "#{proposal.id}"
        'data-role': 'm-proposal'
        id : "#{id}"
        class : "#{ConsiderIt.ProposalListView.childClass}"
        'data-activity': if proposal.has_participants() then 'proposal-has-activity' else 'proposal-no-activity'


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
    console.log 'CREATING'
    attrs = 
      name : 'Should we ... ?'
      description : "We're thinking about ..."

    new_proposal = @collection.create attrs, {
      wait: true
      at: 0
      success: => 
        console.log 'SUCCESS!'
        new_view = @getViewByModel new_proposal
        console.log new_view
        new_view.$el.find('.m-proposal-description').trigger('click')
        new_view.$el.attr('data-visibility', 'unpublished')
  
    }

  delete_proposal : (proposal) ->
    ConsiderIt.router.navigate(Routes.root_path(), {trigger: true})
    @collection.remove proposal
