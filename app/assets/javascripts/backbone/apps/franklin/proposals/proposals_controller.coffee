@ConsiderIt.module "Franklin.Proposals", (Proposals, App, Backbone, Marionette, $, _) ->

  class Proposals.RegionController extends App.Controllers.Base

    initialize : (options = {}) ->
      layout = @getLayout()

      @listenTo layout, 'show', =>
        active_controller = new Proposals.ActiveListController
          region : layout.activeRegion
          parent_controller : @

        inactive_controller = new Proposals.InactiveListController
          region : layout.pastRegion
          parent_controller : @

      @region.show layout

    getLayout : ->
      new Proposals.ProposalsRegionLayout


  class Proposals.AbstractListController extends App.Controllers.Base

    initialize : (options = {}) ->

      layout = @getLayout()

      @listenTo layout, 'show', => @handleShow layout

      @listenTo App.vent, 'user:signin user:signout', => @handleShow layout

      @region.show layout
      @layout = layout

    handleShow : (layout) ->
      return if layout.isClosed

      proposals_view = @getProposals @is_active

      @sortCollection {collection: proposals_view.collection, sort_by: 'activity'}

      pagination_view = @getPaginationView proposals_view.collection
      filter_view = @getFilterView proposals_view.collection

      @listenTo proposals_view, 'before:item:added', (view) -> @handleBeforeViewAdded view
      @listenTo proposals_view, 'childview:proposal:deleted', (view) => @handleProposalDeleted proposals_view.collection, view.model
      @listenTo filter_view, 'sort:requested', (sort_by) => @handleSortRequested proposals_view.collection, sort_by
      @listenTo pagination_view, 'pagination:show_more', => @handleShowMore proposals_view.collection
      @listenTo App.vent, 'proposals:reset', => @handleReset proposals_view.collection, @is_active

      layout.proposalsRegion.show proposals_view
      layout.filtersRegion.show filter_view
      layout.paginationRegion.show pagination_view

      @proposals_view = proposals_view


    handleBeforeViewAdded : (view) ->
      new App.Franklin.Proposal.SummaryController
        view : view
        region : new Backbone.Marionette.Region { el : view.el }      
        parent_controller : @

    handleSortRequested : (collection, sort_by) ->
      @requestProposals collection, @is_active, @sortCollection, 
        collection: collection
        sort_by: sort_by

    handleShowMore : (collection) ->
      @requestProposals collection, @is_active

    handleProposalDeleted : (collection, model) ->
      collection.fullCollection.remove model
      App.vent.trigger 'proposal:deleted', model

    handleReset : (collection, is_active) ->
      proposals = App.request 'proposals:get'
      @resetCollection proposals, collection, is_active

    requestProposals : (collection, is_active, callback = null, callback_params = {}) ->
      proposals = App.request 'proposals:get', true
      App.execute "when:fetched", proposals, =>
        @resetCollection proposals, collection, is_active
        callback(callback_params) if callback

    resetCollection : (proposals, collection, is_active) ->        
      filtered_collection = proposals.where {active : is_active}
      collection.fullCollection.reset filtered_collection

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


  class Proposals.ActiveListController extends Proposals.AbstractListController
    is_active : true


    handleShow : (layout) ->
      super layout
      can_create = App.request "auth:can_create_proposal"
      if can_create
        create_view = @getCreateView()
        @listenTo create_view, 'proposal:new:requested', => @handleNewProposal()
        layout.createRegion.show create_view
      else
        layout.createRegion.reset()


    handleNewProposal : ->
      attrs = 
        name : 'Should we ... ?'
        description : "We're thinking about ..."

      proposal = App.request "proposal:create", attrs, 
        wait: true
        success: => 
          @proposals_view.collection.fullCollection.add proposal


    getCreateView : ->
      new Proposals.CreateProposalView




     