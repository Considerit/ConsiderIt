@ConsiderIt.module "Franklin.Proposals", (Proposals, App, Backbone, Marionette, $, _) ->

  class Proposals.ProposalsRegionLayout extends App.Views.Layout
    template: '#tpl_proposals_region_layout'

    regions: 
      activeRegion : '#proposals-container'
      pastRegion : '#proposals-container-completed'

  class Proposals.ProposalsListLayout extends App.Views.Layout
    template: '#tpl_proposals_list_layout'
    
    regions: 
      createRegion : '.proposals-create-region'
      proposalsRegion : '.proposal-list-region'
      filtersRegion : '.proposals-filters'
      paginationRegion : '.proposals-list-pagination'

  class Proposals.CreateProposalView extends App.Views.ItemView
    template: '#tpl_proposals_list_create'

    events :
      'click .new-proposal-submit' : 'createNewProposal'

    createNewProposal : (ev) ->
      @trigger 'proposal:new:requested'


  class Proposals.FilterView extends App.Views.ItemView
    template: '#tpl_proposals_list_filters'
    sort_by : 'activity'

    initialize : (options = {}) ->
      super options
      @listenTo @collection, 'reset', =>
        @updateSelectedFilter()

      @listenTo App.vent, 'proposals:fetched:done', =>
        @render() 

    serializeData : ->
      sortable_fields : [ 
        {name: 'Most active', target: 'activity'}, 
        {name: 'Newness', target: 'created_at'} ]
      data_loaded : App.request "proposals:are_fetched"

    updateSelectedFilter : ->
      @$el.find(".proposallist-sort.selected").removeClass 'selected'    
      @$el.find("[data-target='#{@sort_by}']").addClass 'selected'

    onShow : ->
      @updateSelectedFilter()      

    events :
      'click .proposallist-sort' : 'sortProposalsTo'

    sortProposalsTo : (ev) ->  
      @sort_by = $(ev.target).data('target')
      @trigger 'sort:requested', @sort_by
      @$el.moveToBottom()


  class Proposals.PaginationView extends App.Views.ItemView
    template: '#tpl_proposal_list_pagination'

    initialize : (options = {} ) ->
      super options
      @listenTo @collection, 'reset add remove', =>
        @render()

    serializeData : ->
      params = _.extend {}, @collection.state,
        page_set : (page for page in [@collection.state.firstPage..@collection.state.lastPage])
        data_loaded : App.request "proposals:are_fetched"
        prompt: if @options.is_active then "Show more ongoing conversations" else "Show past conversations"
        has_more_models : (@options.total_models > @collection.state.pageSize) || @collection.state.totalPages > 1

      params

    events : 
      'click [data-target="load-proposals"]' : 'showMoreRequested'
      'click [data-target="proposallist:first"]' : 'gotoFirst'
      'click [data-target="proposallist:prev"]' : 'gotoPrev'
      'click [data-target="proposallist:next"]' : 'gotoNext'
      'click [data-target="proposallist:last"]' : 'gotoLast'
      'click [data-target="proposallist:page"]' : 'gotoPage'

    proposalsLoaded : ->
      _.delay =>
        @$el.moveToBottom()
      , 300

    showMoreRequested : (ev) ->
      @trigger 'pagination:show_more'


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
    itemViewContainer : 'ul.proposal-list' 

    initialize : (options = {}) ->
      super options

    serializeData : ->
      is_active : @is_active
      data_loaded : App.request "proposals:are_fetched"
      tenant : App.request('tenant:get').attributes

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
      @listenTo App.vent, 'proposals:fetched:done', =>
        @render() 





