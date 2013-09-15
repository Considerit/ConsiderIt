@ConsiderIt.module "Franklin.Proposals", (Proposals, App, Backbone, Marionette, $, _) ->

  class Proposals.ProposalsRegionLayout extends App.Views.Layout
    template: '#tpl_proposals_region_layout'

    regions: 
      activeRegion : '#m-proposals-container'
      pastRegion : '#m-proposals-container-completed'

  class Proposals.ProposalsListLayout extends App.Views.Layout
    template: '#tpl_proposals_list_layout'
    
    regions: 
      createRegion : '.m-proposals-create'
      proposalsRegion : '.m-proposal-list-region'
      filtersRegion : '.m-proposals-filters'
      paginationRegion : '.m-proposals-list-pagination'

  class Proposals.CreateProposalView extends App.Views.ItemView
    template: '#tpl_proposals_list_create'

    events :
      'click .m-new-proposal-submit' : 'createNewProposal'

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
      @$el.find(".m-proposallist-sort.selected").removeClass 'selected'    
      @$el.find("[data-target='#{@sort_by}']").addClass 'selected'

    onShow : ->
      @updateSelectedFilter()      

    events :
      'click .m-proposallist-sort' : 'sortProposalsTo'

    sortProposalsTo : (ev) ->  
      @sort_by = $(ev.target).data('target')
      @trigger 'sort:requested', @sort_by
      window.ensure_el_in_view @$el


  class Proposals.PaginationView extends App.Views.ItemView
    template: '#tpl_proposal_list_pagination'

    initialize : (options = {} ) ->
      super options
      @listenTo @collection, 'reset add remove', =>
        @render()

    serializeData : ->
      _.extend {}, @collection.state,
        page_set : (page for page in [@collection.state.firstPage..@collection.state.lastPage])
        data_loaded : App.request "proposals:are_fetched"
        prompt: if @options.is_active then "Show more ongoing conversations" else "Show past conversations"

    events : 
      'click .m-pointlist-pagination-showmore' : 'showMoreRequested'
      'click [data-target="proposallist:first"]' : 'gotoFirst'
      'click [data-target="proposallist:prev"]' : 'gotoPrev'
      'click [data-target="proposallist:next"]' : 'gotoNext'
      'click [data-target="proposallist:last"]' : 'gotoLast'
      'click [data-target="proposallist:page"]' : 'gotoPage'

    showMoreRequested : (ev) ->
      @trigger 'pagination:show_more'

    gotoFirst : (ev) ->
      ev.preventDefault()
      @collection.getFirstPage()
      window.ensure_el_in_view @$el

    gotoPrev : (ev) ->
      ev.preventDefault()
      @collection.getPreviousPage()
      window.ensure_el_in_view @$el

    gotoNext : (ev) ->
      ev.preventDefault()
      @collection.getNextPage()
      window.ensure_el_in_view @$el

    gotoLast : (ev) ->
      ev.preventDefault()
      @collection.getLastPage()
      window.ensure_el_in_view @$el

    gotoPage : (ev) ->
      ev.preventDefault()
      page = $(ev.target).data('page')

      @collection.getPage(page)
      window.ensure_el_in_view @$el


  class Proposals.ProposalsListView extends App.Views.CompositeView
    template: '#tpl_proposals_list'
    itemViewContainer : 'ul.m-proposal-list' 

    initialize : (options = {}) ->
      super options

    serializeData : ->
      is_active : @is_active
      data_loaded : App.request "proposals:are_fetched"

    buildItemView : (proposal) ->
      if App.request "auth:can_edit_proposal", proposal
        view_cls = App.Franklin.Proposal.ModifiableProposalSummaryView
      else
        view_cls = App.Franklin.Proposal.ProposalSummaryView

      view = new view_cls
        model: proposal
        class : 'm-proposal'
        attributes : 
          'data-id': "#{proposal.id}"
          'data-role': 'm-proposal'
          'data-activity': if proposal.has_participants() then 'proposal-has-activity' else 'proposal-no-activity'
          'data-status': if proposal.get('active') then 'proposal-active' else 'proposal-inactive'
          'data-visibility': if proposal.get('published') then 'published' else 'unpublished'

      view

  class Proposals.ActiveProposalsList extends Proposals.ProposalsListView
    is_active : true


  class Proposals.PastProposalsList extends Proposals.ProposalsListView
    is_active : false




