@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->

  class Proposal.SummaryController extends App.Controllers.Base
    initialize : (options = {}) ->
      @model = options.model || options.view.model

      @modifiable = App.request "auth:can_edit_proposal", @model
      layout = @getLayout @model

      @listenTo layout, 'show', =>
        proposal_view = @getProposalDescription @model
        @setupProposal proposal_view
        layout.proposalRegion.show proposal_view

        if @model.get 'published'
          summary_view = @getSummaryView @model
          @setupSummary summary_view
          layout.summaryRegion.show summary_view

        if @modifiable
          @setupModifiable layout, @model

    setupProposal : (view) ->
      @listenTo view, 'proposal:clicked', =>
        App.navigate Routes.new_position_proposal_path( @model.long_id ), {trigger: true}

    setupSummary : (view) ->
      view

    setupModifiable : (view, model) ->
      @listenTo view, 'proposal:published', (proposal_attrs, position_attrs) =>
        model.set proposal_attrs
        position = App.request 'position:create', position_attrs
        model.setUserPosition position.id  

        App.navigate Routes.new_position_proposal_path(model.long_id), {trigger: true}


      @listenTo view, 'status_dialog', =>

        dialogview = new Proposal.ProposalStatusDialogView
          model : model

        @listenTo dialogview, 'proposal:updated', (data) =>
          model.set {access_list: data.access_list, active: data.active, publicity: data.publicity}
          view.render()
          dialog.close()

        dialog = App.request 'dialog:new', dialogview,
          class : 'm-proposal-admin-status'

      @listenTo view, 'publicity_dialog', (view) =>
        dialogview = new Proposal.ProposalPublicityDialogView
          model : model

        @listenTo dialogview, 'proposal:updated', (data) =>
          model.set {access_list: data.access_list, active: data.active, publicity: data.publicity}
          view.render()
          dialog.close()

        dialog = App.request 'dialog:new', dialogview,
          class : 'm-proposal-admin-publicity'

    getProposalDescription : (proposal) ->
      if proposal.get 'published'
        new Proposal.SummaryProposalDescription
          model : proposal
      else
        new Proposal.UnpublishedProposalDescription
          model : proposal


    getSummaryView : (model) ->
      new Proposal.SummaryResultsView
        model : model

    getLayout : (model) ->
      if @options.view 
        view = @options.view
      else 
        if @modifiable
          view_cls = Proposal.ModifiableProposalSummaryView
        else
          view_cls = Proposal.ProposalSummaryView

        view = new view_cls
          model: model
          class : 'm-proposal'
          attributes : 
            'data-id': "#{proposal.id}"
            'data-role': 'm-proposal'
            'data-activity': if model.has_participants() then 'proposal-has-activity' else 'proposal-no-activity'
            'data-status': if model.get('active') then 'proposal-active' else 'proposal-inactive'
            'data-visibility': if model.get('published') then 'published' else 'unpublished'

      view