@ConsiderIt.module "Franklin.Proposals", (Proposals, App, Backbone, Marionette, $, _) ->

  class Proposals.RegionController extends App.Controllers.Base

    initialize : (options = {}) ->
      layout = @getLayout()

      @listenTo layout, 'show', =>
        active_controller = new Proposals.ActiveListController
          region : layout.activeRegion
          parent_controller : @
          total_models : App.request('proposals:totals')[0]

        inactive_controller = new Proposals.InactiveListController
          region : layout.pastRegion
          parent_controller : @
          total_models : App.request('proposals:totals')[1]


        if @options.last_proposal_id
          #TODO: if not on page, go to page where proposal lives
          $last_proposal = layout.$el.find(".m-proposal[data-id='#{@options.last_proposal_id}']")
          if $last_proposal.length == 1
            $last_proposal.moveToTop() # {scroll: false}

      @region.show layout

    getLayout : ->
      new Proposals.ProposalsRegionLayout


  class Proposals.AbstractListController extends App.Controllers.Base

    initialize : (options = {}) ->

      layout = @getLayout()

      @listenTo layout, 'show', => 
        @handleShow layout

      @region.show layout

      # Not sure why the following was important. It was creating problems with private discussion workflow.
      # @listenTo App.vent, 'proposals:fetched:done proposals:added', => 
      #   @region.reset()
      #   @region.show layout

      @layout = layout

    handleShow : (layout) ->
      proposals_view = @setupProposalsView @is_active
      filter_view = @setupFilterView proposals_view.collection
      pagination_view = @setupPaginationView proposals_view.collection

      @listenTo App.vent, "proposals:show_more_handled:#{@is_active}", ->
        pagination_view.proposalsLoaded()

      layout.proposalsRegion.show proposals_view
      layout.filtersRegion.show filter_view
      layout.paginationRegion.show pagination_view

      @proposals_view = proposals_view

    setupProposalsView : (is_active) ->
      all_proposals = App.request('proposals:get')

      filtered_collection = all_proposals.where({active : is_active})

      @collection = new App.Entities.PaginatedProposals filtered_collection,
        fullCollection : filtered_collection
        total_models : @options.total_models

      view = @getProposals @is_active, @collection
      @sortCollection {collection: view.collection, sort_by: 'activity'}
      @listenTo view, 'before:item:added', (vw) -> @handleBeforeViewAdded vw
      @listenTo App.vent, 'proposal:deleted', (model) => @handleProposalDeleted @collection, model
      @listenTo App.vent, 'proposals:reset', => @handleReset view.collection, @is_active
      view

    setupPaginationView : (collection) ->
      view = @getPaginationView collection
      @listenTo view, 'pagination:show_more', => @handleShowMore collection, view
      view

    setupFilterView : (collection) ->
      view = @getFilterView collection
      @listenTo view, 'sort:requested', (sort_by) => 
        @handleSortRequested collection, sort_by
      view

    handleBeforeViewAdded : (view) ->
      new App.Franklin.Proposal.ProposalController
        view : view
        region : new Backbone.Marionette.Region { el : view.el }
        model : view.model
        parent_controller : @
        proposal_state : App.Franklin.Proposal.State.collapsed

    handleSortRequested : (collection, sort_by) ->
      @requestProposals collection, @is_active, @sortCollection, 
        collection: collection
        sort_by: sort_by

    handleShowMore : (collection, view) ->
      @requestProposals collection, @is_active, =>
        App.vent.trigger "proposals:show_more_handled:#{@is_active}"

    handleProposalDeleted : (collection, model) ->
      collection.fullCollection.remove model

    handleReset : (collection, is_active) ->
      proposals = App.request 'proposals:get'
      @resetCollection proposals, collection, is_active

    requestProposals : (collection, is_active, callback = null, callback_params = {}) ->
      proposals = App.request 'proposals:get', true

      App.execute 'when:fetched', proposals, =>
        proposals = App.request 'proposals:get'
        @resetCollection proposals, collection, is_active
        callback(callback_params) if callback

    resetCollection : (proposals, collection, is_active) -> 
      if collection.fullCollection # conditional for IE 8
        filtered_collection = proposals.where {active : is_active}
        collection.fullCollection.reset filtered_collection

    sortCollection : ({collection, sort_by}) ->
      if collection.fullCollection # conditional for IE 8    
        collection.setSorting sort_by, 1
        collection.fullCollection.sort()

    getLayout : ->
      new Proposals.ProposalsListLayout

    getPaginationView : (collection) ->
      new Proposals.PaginationView
        collection: collection
        is_active : @is_active
        total_models : @options.total_models

    getFilterView : (collection) ->
      new Proposals.FilterView
        collection: collection
        is_active : @is_active

    getProposals : (is_active, collection) ->

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

    initialize : (options = {}) ->
      super options

      @listenTo App.vent, 'user:signin user:signout', => 
        @createCreateRegion @layout

    handleShow : (layout) ->
      super layout
      @createCreateRegion layout

    createCreateRegion : (layout) ->      
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
        description : "Here are some details about what we're thinking about ..."

      App.request "proposal:create", attrs, 
        wait: true
        success: (proposal) => 
          @proposals_view.collection.add proposal
          App.navigate Routes.new_position_proposal_path(proposal.id), {trigger: true}


    getCreateView : ->
      new Proposals.CreateProposalView




     