@ConsiderIt.module "Franklin.Proposals", (Proposals, App, Backbone, Marionette, $, _) ->

  class Proposals.ProposalsRegionController extends App.Controllers.Base

    initialize : (options = {}) ->
      layout = @getLayout()

      @listenTo layout, 'show', =>

        tenant = App.request('tenant')

        if tenant.get('enable_hibernation')
          inactive_controller = new Proposals.InactiveProposalsController
            region : layout.activeRegion
            parent_controller : @
            num_proposals : App.request('proposals:totals')[1]

        else
          active_controller = new Proposals.ActiveProposalsController
            region : layout.activeRegion
            parent_controller : @
            num_proposals : App.request('proposals:totals')[0]

          inactive_controller = new Proposals.InactiveProposalsController
            region : layout.pastRegion
            parent_controller : @
            num_proposals : App.request('proposals:totals')[1]


        if @options.last_proposal_id
          #TODO: if not on page, go to page where proposal lives
          $last_proposal = layout.$el.find("[role='proposal'][id='#{@options.last_proposal_id}']")
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

      @layout = layout

    handleShow : (layout) ->
      proposals_view = @setupProposalsView @is_active
      filter_view = @setupFilterView proposals_view.collection
      pagination_view = @setupPaginationView proposals_view.collection

      @listenTo App.vent, "proposals:#{@is_active}_proposals_were_loaded", ->
        pagination_view.proposalsWereLoaded()

      # When proposals are fetched from the server, we need to reevaluate which proposals should be in this list. It is creating problems with private discussion workflow.
      @listenTo App.vent, 'proposals:just_fetched_from_server proposals:added', => 
        all_proposals = App.request('proposals:get')
        filtered_proposals = all_proposals.where({active : @is_active})
        proposals_view.collection.add filtered_proposals, {merge: true}
        # @region.reset()
        # @region.show layout

      layout.proposalsRegion.show proposals_view
      layout.sortRegion.show filter_view
      layout.paginationRegion.show pagination_view

      @proposals_view = proposals_view


    setupProposalsView : (is_active) ->
      all_proposals = App.request('proposals:get')
      filtered_proposals = all_proposals.where({active : is_active})

      @collection = new App.Entities.PaginatedProposals filtered_proposals,
        fullCollection : filtered_proposals
        num_proposals : @options.num_proposals

      view = @getProposals @is_active, @collection
      @sortCollection {collection: view.collection, sort_by: 'activity'}
      @listenTo view, 'before:item:added', (vw) -> @initializeControllerForProposalView vw
      @listenTo App.vent, 'proposal:deleted', (model) => @proposalWasDeleted @collection, model
      @listenTo App.vent, 'proposals:reset', => @proposalsWereReset view.collection, @is_active
      view

    setupPaginationView : (collection) ->
      pagination_view = @getPaginationView collection
      @listenTo pagination_view, 'proposals:please_fetch_proposals_from_server', => @fetchProposals collection, pagination_view
      pagination_view

    setupFilterView : (collection) ->
      filter_view = @getFilterView collection
      @listenTo filter_view, 'proposals:please_sort', (sort_by) => 
        @sortProposals collection, sort_by
      filter_view

    initializeControllerForProposalView : (view) ->
      ctrl = new App.Franklin.Proposal.ProposalController
        view : view
        region : new Backbone.Marionette.Region { el : view.el }
        model : view.model
        parent_controller : @
        proposal_state : App.Franklin.Proposal.State.Summary

      ctrl

    sortProposals : (collection, sort_by) ->
      @requestProposals collection, @is_active, @sortCollection, 
        collection: collection
        sort_by: sort_by

    fetchProposals : (collection, view) ->
      @requestProposals collection, @is_active, =>
        App.vent.trigger "proposals:#{@is_active}_proposals_were_loaded"

    proposalWasDeleted : (collection, model) ->
      collection.fullCollection.remove model

    proposalsWereReset : (collection, is_active) ->
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
        filtered_proposals = proposals.where {active : is_active}
        collection.fullCollection.reset filtered_proposals

    sortCollection : ({collection, sort_by}) ->
      if collection.fullCollection # conditional for IE 8    
        collection.setSorting sort_by, 1
        collection.fullCollection.sort()

    getLayout : ->
      new Proposals.ProposalsLayout

    getPaginationView : (collection) ->
      new Proposals.PaginationView
        collection: collection
        is_active : @is_active
        num_proposals : @options.num_proposals

    getFilterView : (collection) ->
      new Proposals.SortProposalsView
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

  class Proposals.InactiveProposalsController extends Proposals.AbstractListController
    is_active : false


  class Proposals.ActiveProposalsController extends Proposals.AbstractListController
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
        @listenTo create_view, 'proposals:please_create_new', => @createNewProposal()
        layout.createRegion.show create_view
      else
        layout.createRegion.reset()


    createNewProposal : ->
      attrs = 
        name : 'Should we ... ?'
        description : "Here are some details about what we're thinking about ..."

      App.request "proposal:create", attrs, 
        wait: true
        success: (proposal) => 
          @proposals_view.collection.add proposal
          App.navigate Routes.new_opinion_proposal_path(proposal.id), {trigger: true}


    getCreateView : ->
      new Proposals.CreateNewProposalView




     