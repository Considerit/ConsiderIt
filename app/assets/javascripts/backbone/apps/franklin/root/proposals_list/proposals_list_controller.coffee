@ConsiderIt.module "Franklin.Root.ProposalsList", (ProposalsList, App, Backbone, Marionette, $, _) ->

  class ProposalsList.RegionController extends App.Controllers.Base

    initialize : (options = {}) ->
      layout = @getLayout()

      @listenTo layout, 'show', =>
        active_controller = new ProposalsList.ActiveListController
          region : layout.activeRegion

        inactive_controller = new ProposalsList.InactiveListController
          region : layout.pastRegion

      @region.show layout

    getLayout : ->
      new ProposalsList.ProposalsRegionLayout


  class ProposalsList.AbstractListController extends App.Controllers.Base

    initialize : (options = {}) ->

      layout = @getLayout()

      @listenTo layout, 'show', =>

        proposals_view = @getProposals @is_active

        @sortCollection {collection: proposals_view.collection, sort_by: 'activity'}

        pagination_view = @getPaginationView proposals_view.collection
        filter_view = @getFilterView proposals_view.collection

        @listenTo proposals_view, 'childview:proposal:deleted', (model) =>
          @collection.remove model
          App.vent.trigger 'proposal:deleted', model

        @listenTo filter_view, 'sort:requested', (sort_by) => 
          @requestProposals proposals_view.collection, @is_active, @sortCollection, 
            collection: proposals_view.collection
            sort_by: sort_by

        @listenTo pagination_view, 'pagination:show_more', =>
          @requestProposals proposals_view.collection, @is_active

        layout.proposalsRegion.show proposals_view
        layout.filtersRegion.show filter_view
        layout.paginationRegion.show pagination_view

        @proposals_view = proposals_view

      @listenTo App.vent, 'user:signin user:signout', => @render()

      @layout = layout

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
      new ProposalsList.ProposalsListLayout

    getPaginationView : (collection) ->
      new ProposalsList.PaginationView
        collection: collection
        is_active : @is_active

    getFilterView : (collection) ->
      new ProposalsList.FilterView
        collection: collection
        is_active : @is_active

    getProposals : (is_active) ->
      all_proposals = App.request('proposals:get')
      filtered_collection = all_proposals.where({active : is_active})

      collection = new App.Entities.PaginatedProposals filtered_collection,
        fullCollection : filtered_collection

      if is_active
        list = new ProposalsList.ActiveProposalsList
          collection: collection
      else
        list = new ProposalsList.PastProposalsList
          collection: collection

      list

  class ProposalsList.InactiveListController extends ProposalsList.AbstractListController
    is_active : false

    initialize : (options = {}) ->
      super options
      @region.show @layout       


  class ProposalsList.ActiveListController extends ProposalsList.AbstractListController
    is_active : true

    initialize : (options = {} ) ->

      super options

      @listenTo @layout, 'show', =>
        can_create = App.request "auth:can_create_proposal"
        if can_create
          create_view = @getCreateView()
          @listenTo create_view, 'proposal:new:requested', =>
            attrs = 
              name : 'Should we ... ?'
              description : "We're thinking about ..."

            proposal = App.request "proposal:create", attrs, 
              wait: true
              success: => 
                @proposals_view.prepareNewProposal proposal
            @proposals_view.collection.add proposal, { at : 0 }

          @layout.createRegion.show create_view

          @listenTo @layout, 'childview:proposal:published', (view, proposal_attrs, position_attrs) =>
            #TODO: bring this in line with new data architecture
            view.model.set _.extend data,
              position: position_attrs
              points: {}
            view.model.long_id = view.model.get('long_id')

          @listenTo @proposals_view, 'childview:status_dialog', (view) =>

            view = new ProposalsList.ProposalStatusDialogView
              model : view.model

            @listenTo view, 'proposal:updated', (view, data) =>
              view.model.set {access_list: data.access_list, active: data.active, publicity: data.publicity}
              view.render()
              dialog.close()

            dialog = App.request 'dialog:new', view,
              class : 'm-proposal-admin-status'

          @listenTo @proposals_view, 'childview:publicity_dialog', (view) =>
            view = new ProposalsList.ProposalPublicityDialogView
              model : view.model

            @listenTo view, 'proposal:updated', (view, data) =>
              view.model.set {access_list: data.access_list, active: data.active, publicity: data.publicity}
              view.render()
              dialog.close()

            dialog = App.request 'dialog:new', view,
              class : 'm-proposal-admin-publicity'

      @region.show @layout

    getCreateView : ->
      new ProposalsList.CreateProposalView




     