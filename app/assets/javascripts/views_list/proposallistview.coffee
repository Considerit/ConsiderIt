class ConsiderIt.ProposalListView extends Backbone.CollectionView

  proposals_header_template : _.template($('#tpl_proposal_list_header').html())
  proposals_create_template : _.template($('#tpl_proposal_list_new_conversation').html())
  proposals_pagination_template : _.template($('#tpl_proposal_list_pagination').html())

  itemView : ConsiderIt.ProposalView
  @childClass : 'm-proposal'
  listSelector : '.m-proposal-list'

  initialize : (options) -> 
    @sort_selected = 'activity'
    # @filter_selected = 'active'
    super
    @data_loaded = false
    @is_active = options.active

    #@filter_proposals()
    @sort_proposals()

    @listenTo ConsiderIt.app, 'user:signout', @post_signout
    @listenTo ConsiderIt.app, 'proposal:deleted', (proposal) => @delete_proposal(proposal)

  post_signout : -> view.post_signout() for own cid, view of @viewsByCid

  render : -> 
    # @undelegateEvents()
    super
    @render_pagination()
    @render_header()


  #TODO: do this when login as admin
  render_header : ->
    $heading_el = @proposals_header_template({
      is_admin : ConsiderIt.roles.is_admin
      selected_sort : @sort_selected
      selected_filter : @filter_selected
      })

    $cur_heading = @$el.find('.m-proposals-list-header')
    if $cur_heading.length > 0
      $cur_heading.replaceWith $heading_el
    else
      @$el.append($heading_el)


    can_create = ConsiderIt.current_user.is_logged_in() && (ConsiderIt.roles.is_admin || ConsiderIt.roles.is_manager || ConsiderIt.current_tenant.get('enable_user_conversations'))

    if @is_active && can_create && !@$create_el?
      @$create_el = $(@proposals_create_template())
      @$el.prepend(@$create_el)
    else if !can_create && @$create_el?
      @$create_el.remove()
      @$create_el = null


  render_pagination : ->
    $pagination_block = @proposals_pagination_template _.extend(@collection.info(), {
      data_loaded : @data_loaded
      prompt: if @is_active then "Show more ongoing conversations" else "Show completed conversations"
    })

    $cur_pagination = @$el.find('.m-proposals-list-pagination')
    if $cur_pagination.length > 0
      $cur_pagination.replaceWith $pagination_block
    else
      @$el.append $pagination_block

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
        'data-visibility': if proposal.get('published') then 'published' else 'unpublished'

  #handlers
  events :
    'click .m-new-proposal-submit' : 'create_new_proposal'
    'click .m-proposallist-sort' : 'sort_proposals_to'
    #'click .m-proposallist-filter' : 'filter_proposals_to'
    'click .m-pointlist-pagination-showmore' : 'do_after_all_data_loaded'

    'click [data-target="proposallist:first"]' : 'goto_first'
    'click [data-target="proposallist:prev"]' : 'goto_prev'
    'click [data-target="proposallist:next"]' : 'goto_next'
    'click [data-target="proposallist:last"]' : 'goto_last'
    'click [data-target="proposallist:page"]' : 'goto_page'

  do_after_all_data_loaded : (callback) ->

    if !@data_loaded
      @data_loaded = true
      $.get Routes.proposals_path(), { active: @is_active }, (data) => 
        @collection.add_proposals data        
        @sort_proposals()
        #@filter_proposals()
    else
      callback.apply(@) if callback

  sort_proposals_to : (ev) ->   
    @sort_selected = $(ev.target).data('target')
    @do_after_all_data_loaded(@sort_proposals)

  # filter_proposals_to : (ev) ->
  #   @filter_selected = $(ev.target).data('target')
  #   @do_after_all_data_loaded(@filter_proposals)

  sort_proposals : ->
    @collection.setSort( @sort_selected, 'desc')

    @render_header()
    @render_pagination()

    @collection.updateList()

  # filter_proposals : ->

  #   if @filter_selected == 'all'
  #     @collection.setFieldFilter()
  #   else if @filter_selected == '-active'
  #     @collection.setFieldFilter [{
  #       field : 'active'
  #       type : 'equalTo' 
  #       value : false
  #     }]
  #   else if @filter_selected == 'active'
  #     @collection.setFieldFilter [{
  #       field : 'active'
  #       type : 'equalTo' 
  #       value : true
  #     }]    

  #   @render_header()
  #   @render_pagination()
  #   @collection.updateList()

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
    if @collection.get proposal.id
      ConsiderIt.router.navigate(Routes.root_path(), {trigger: true})
      @collection.remove proposal


  goto_first : (ev) ->
    ev.preventDefault()
    @collection.goTo(1)

  goto_prev : (ev) ->
    ev.preventDefault()
    @collection.previousPage()

  goto_next : (ev) ->
    ev.preventDefault()
    @collection.nextPage()

  goto_last : (ev) ->
    ev.preventDefault()
    @collection.goTo(@collection.information.lastPage)

  goto_page : (ev) ->
    ev.preventDefault()
    page = $(ev.target).data('page')
    @collection.goTo(page)

