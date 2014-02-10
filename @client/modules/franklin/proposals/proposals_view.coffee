@ConsiderIt.module "Franklin.Proposals", (Proposals, App, Backbone, Marionette, $, _) ->

  class Proposals.ProposalsRegionLayout extends App.Views.Layout
    template: '#tpl_proposals_region_layout'
    className: 'proposals_region_layout'

    regions: 
      activeRegion : '#active-proposals-region'
      pastRegion : '#past-proposals-region'

  class Proposals.ProposalsLayout extends App.Views.Layout
    template: '#tpl_proposals_layout'
    className: 'proposals_layout'

    regions: 
      createRegion : '.proposals-create-region'
      proposalsRegion : '.proposals-list-region'
      filtersRegion : '.proposals-filters'
      paginationRegion : '.proposals-list-pagination'

  class Proposals.CreateNewProposalView extends App.Views.ItemView
    template: '#tpl_create_new_proposal'
    className : 'new_proposal_view'

    events :
      'click .new-proposal-submit' : 'createNewProposal'

    createNewProposal : (ev) ->
      @trigger 'proposals:please_create_new'


  class Proposals.SortProposalsView extends App.Views.ItemView
    template: '#tpl_sort_proposals'
    sort_by : 'activity'
    className : 'proposals_sort_view'

    initialize : (options = {}) ->
      super options
      @listenTo @collection, 'reset', =>
        @applySortOrder()

      @listenTo App.vent, 'proposals:just_fetched_from_server', =>
        @render() 

    serializeData : ->
      sortable_fields : [ 
        {name: 'Most active', target: 'activity'}, 
        {name: 'Newness', target: 'created_at'} ]
      data_loaded : App.request "proposals:fetched_from_server?"

    applySortOrder : ->
      @$el.find(".sort_proposals_by.selected").removeClass 'selected'    
      @$el.find("[data-target='#{@sort_by}']").addClass 'selected'

    onShow : ->
      @applySortOrder()      

    events :
      'click .sort_proposals_by' : 'sortProposalsTo'

    sortProposalsTo : (ev) ->  
      @sort_by = $(ev.target).data('target')
      @trigger 'proposals:please_sort', @sort_by
      @$el.moveToBottom()


  class Proposals.PaginationView extends App.Views.ItemView
    template: '#tpl_proposals_pagination'
    className: 'proposals_pagination_view'

    initialize : (options = {} ) ->
      super options
      @listenTo @collection, 'reset add remove', => @render()

    serializeData : ->
      params = _.extend {}, @collection.state,
        page_set : (page for page in [@collection.state.firstPage..@collection.state.lastPage])
        data_loaded : App.request "proposals:fetched_from_server?"
        prompt: if @options.is_active then "Show more ongoing conversations" else "Show past conversations"
        has_more_models : (@options.num_proposals > @collection.state.pageSize) || @collection.state.totalPages > 1

      params

    events : 
      'click [data-target="load-proposals"]' : 'bubbleLoadProposalsRequest'
      'click [data-target="proposals:first_page"]' : 'gotoFirst'
      'click [data-target="proposals:previous_page"]' : 'gotoPrev'
      'click [data-target="proposals:next_page"]' : 'gotoNext'
      'click [data-target="proposals:last_page"]' : 'gotoLast'
      'click [data-target="proposals:goto_page"]' : 'gotoPage'

    proposalsWereLoaded : ->
      _.delay =>
        @$el.moveToBottom()
      , 300

    bubbleLoadProposalsRequest : (ev) ->
      @trigger 'proposals:please_fetch_proposals_from_server'


    gotoFirst : (ev) ->
      ev.preventDefault()
      @collection.getFirstPage()
      @$el.moveToBottom()

    gotoPrev : (ev) ->
      ev.preventDefault()
      @collection.getPreviousPage()
      @$el.moveToBottom()

    gotoNext : (ev) ->
      ev.preventDefault()
      @collection.getNextPage()
      @$el.moveToBottom() 

    gotoLast : (ev) ->
      ev.preventDefault()
      @collection.getLastPage()
      @$el.moveToBottom() 

    gotoPage : (ev) ->
      ev.preventDefault()
      page = $(ev.target).data('page')
      @collection.getPage(page)
      @$el.moveToBottom() 


  class Proposals.ProposalsListView extends App.Views.CompositeView
    template: '#tpl_proposals_list'
    className: 'proposals_list_view'
    itemViewContainer : 'ul.proposals-list' 

    initialize : (options = {}) ->
      super options

    serializeData : ->
      is_active : @is_active
      data_loaded : App.request "proposals:fetched_from_server?"
      tenant : App.request('tenant').attributes

    buildItemView : (proposal) ->
      view_cls = App.Franklin.Proposal.ProposalLayout

      view = new view_cls
        model: proposal
        class : 'proposal'

      view

  class Proposals.ActiveProposalsList extends Proposals.ProposalsListView
    is_active : true


  class Proposals.PastProposalsList extends Proposals.ProposalsListView
    is_active : false

    initialize : (options = {}) ->
      super options
      @listenTo App.vent, 'proposals:just_fetched_from_server', =>
        @render() 





