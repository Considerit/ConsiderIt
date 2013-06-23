class ConsiderIt.ProposalListView extends Backbone.CollectionView
  @proposals_header_template = _.template($('#tpl_proposal_list_header').html())
  @proposals_create_template = _.template($('#tpl_proposal_list_new_conversation').html())

  itemView : ConsiderIt.ProposalView
  @childClass : 'm-proposal'
  listSelector : '.m-proposal-list'

  initialize : (options) -> 
    @sort_selected = 'activity'
    @filter_selected = 'active'
    super

    @data_loaded = false

    @sort_proposals()

    @listenTo ConsiderIt.app, 'proposal:deleted', (proposal) => @delete_proposal(proposal)

    ConsiderIt.router.on 'route:Consider', (long_id) => @do_after_proposal_data_loaded(long_id, "take_position") 
    ConsiderIt.router.on 'route:Aggregate', (long_id) => @do_after_proposal_data_loaded(long_id, "show_results_handler")
    ConsiderIt.router.on 'route:PointDetails', (long_id, point_id) => @do_after_proposal_data_loaded(long_id, "show_point_details_handler", [{point_id : point_id}])
    ConsiderIt.router.on 'route:StaticPosition', (long_id, user_id) => @do_after_proposal_data_loaded(long_id, "prepare_for_static_position", [{user_id : user_id}])



  do_after_proposal_data_loaded : (long_id, callback, callback_params) ->
    proposal = @collection.findWhere({long_id: long_id})
    proposalview = if proposal? then @getViewByModel(proposal) else null

    if proposalview? && proposal.data_loaded
      proposalview[callback].apply(proposalview, callback_params)
    else if proposal?
      $.get Routes.proposal_path(long_id), (data) => 
        proposal.set_data(data)
        proposalview[callback].apply(proposalview, callback_params)
        @listenTo ConsiderIt.app, 'user:signout', @post_signout
    else
      $.get Routes.proposal_path(long_id), (data) => 
        proposal = new ConsiderIt.Proposal(data.proposal)
        @collection.add proposal
        proposal.set_data data
        proposalview = @getViewByModel(proposal)
        proposalview[callback].apply(proposalview, callback_params)
        @listenTo ConsiderIt.app, 'user:signout', @post_signout


  post_signout : -> view.post_signout() for own cid, view of @viewsByCid

  render : -> 
    # @undelegateEvents()
    super
    @render_header()


  #TODO: do this when login as admin
  render_header : ->
    #@$el.find('.m-proposals-list-header').remove()

    $heading_el = ConsiderIt.ProposalListView.proposals_header_template({
      is_admin : ConsiderIt.roles.is_admin
      selected_sort : @sort_selected
      selected_filter : @filter_selected
      })

    $cur_heading = @$el.find('.m-proposals-list-header')
    if $cur_heading.length > 0
      $cur_heading.replaceWith $heading_el
    else
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
        'data-status': if proposal.get('active') then 'proposal-active' else 'proposal-inactive'


  #handlers
  events :
    'click .m-new-proposal-submit' : 'create_new_proposal'
    'click .m-proposallist-sort' : 'sort_proposals_to'
    'click .m-proposallist-filter' : 'filter_proposals_to'

  do_after_all_data_loaded : (callback) ->

    if !@data_loaded
      @data_loaded = true
      $.get Routes.proposals_path(), (data) => 
        @collection.add_proposals data
        @sort_proposals()
        @filter_proposals()
    else
      callback.apply(@)

  sort_proposals_to : (ev) ->   
    @sort_selected = $(ev.target).data('target')
    @do_after_all_data_loaded(@sort_proposals)

  filter_proposals_to : (ev) ->
    @filter_selected = $(ev.target).data('target')
    @do_after_all_data_loaded(@filter_proposals)

  sort_proposals : ->
    @collection.setSort( @sort_selected, 'desc')

    @render_header()
    @collection.updateList()

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
        new_view = @getViewByModel new_proposal
        new_view.$el.find('.m-proposal-description').trigger('click')
        new_view.$el.attr('data-visibility', 'unpublished')
  
    }

  delete_proposal : (proposal) ->
    ConsiderIt.router.navigate(Routes.root_path(), {trigger: true})
    @collection.remove proposal
