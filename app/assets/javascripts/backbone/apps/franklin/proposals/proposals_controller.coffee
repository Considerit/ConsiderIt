@ConsiderIt.module "Franklin.Proposals", (Proposals, App, Backbone, Marionette, $, _) ->

  class Proposals.RegionController extends App.Controllers.Base

    initialize : (options = {}) ->
      layout = @getLayout()

      @listenTo layout, 'show', =>
        active_controller = new Proposals.ActiveListController
          region : layout.activeRegion

        inactive_controller = new Proposals.InactiveListController
          region : layout.pastRegion

      @region.show layout

    getLayout : ->
      new Proposals.ProposalsRegionLayout


  class Proposals.AbstractListController extends App.Controllers.Base

    initialize : (options = {}) ->

      layout = @getLayout()

      @listenTo layout, 'show', =>

        proposals_view = @getProposals @is_active

        @sortCollection {collection: proposals_view.collection, sort_by: 'activity'}

        pagination_view = @getPaginationView proposals_view.collection
        filter_view = @getFilterView proposals_view.collection

        @listenTo proposals_view, 'before:item:added', (view) -> @handleBeforeViewAdded(view)
        @listenTo proposals_view, 'childview:proposal:deleted', (model) => @handleProposalDeleted(model)
        @listenTo filter_view, 'sort:requested', (sort_by) => @handleSortRequested(proposals_view.collection, sort_by)
        @listenTo pagination_view, 'pagination:show_more', => @handleShowMore proposals_view.collection

        layout.proposalsRegion.show proposals_view
        layout.filtersRegion.show filter_view
        layout.paginationRegion.show pagination_view

        @proposals_view = proposals_view

      @listenTo App.vent, 'user:signin user:signout', => @render()

      @layout = layout

    handleBeforeViewAdded : (view) ->
      new App.Franklin.Proposal.SummaryController
        view : view
        region : new Backbone.Marionette.Region { el : view.el }      

    handleSortRequested : (collection, sort_by) ->
      @requestProposals collection, @is_active, @sortCollection, 
        collection: collection
        sort_by: sort_by

    handleShowMore : (collection) ->
      @requestProposals collection, @is_active

    handleProposalDeleted : (model) ->
      @collection.remove model
      App.vent.trigger 'proposal:deleted', model

    requestProposals : (collection, is_active, callback = null, callback_params = {}) ->
      proposals = App.request 'proposals:get', true
      App.execute "when:fetched", proposals, =>
        filtered_collection = proposals.where {active : is_active}
        collection.fullCollection.reset filtered_collection

        callback(callback_params) if callback

    sortCollection : ({collection, sort_by}) ->
      collection.setSorting sort_by, 1
      collection.fullCollection.sort()

    getLayout : ->
      new Proposals.ProposalsListLayout

    getPaginationView : (collection) ->
      new Proposals.PaginationView
        collection: collection
        is_active : @is_active

    getFilterView : (collection) ->
      new Proposals.FilterView
        collection: collection
        is_active : @is_active

    getProposals : (is_active) ->
      all_proposals = App.request('proposals:get')
      filtered_collection = all_proposals.where({active : is_active})

      collection = new App.Entities.PaginatedProposals filtered_collection,
        fullCollection : filtered_collection

      if is_active
        list = new Proposals.ActiveProposalsList
          collection: collection
      else
        list = new Proposals.PastProposalsList
          collection: collection

      list

  class Proposals.InactiveListController extends Proposals.AbstractListController
    is_active : false

    initialize : (options = {}) ->
      super options
      @region.show @layout       


  class Proposals.ActiveListController extends Proposals.AbstractListController
    is_active : true

    initialize : (options = {} ) ->

      super options

      @listenTo @layout, 'show', =>
        can_create = App.request "auth:can_create_proposal"
        if can_create
          create_view = @getCreateView()
          @listenTo create_view, 'proposal:new:requested', => @handleNewProposal()
          @layout.createRegion.show create_view

      @region.show @layout

    handleNewProposal : ->
      attrs = 
        name : 'Should we ... ?'
        description : "We're thinking about ..."

      proposal = App.request "proposal:create", attrs, 
        wait: true
        success: => 
          @proposals_view.prepareNewProposal proposal
      @proposals_view.collection.add proposal, { at : 0 }

    getCreateView : ->
      new Proposals.CreateProposalView




     