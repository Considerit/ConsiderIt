@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->
  class Proposal.ProposalSettingsController extends App.Controllers.StatefulController

    initialize : (options = {}) ->
      @model = options.model
      @layout = @getLayout @model
      @setupLayout @layout

      @region.show @layout

    setupLayout : (layout) ->
      @listenTo layout, 'status_dialog', =>

        dialogview = new Proposal.ProposalStatusDialogView
          model : @model

        @listenTo dialogview, 'proposal:updated', (data) =>
          @model.set {access_list: data.access_list, active: data.active, publicity: data.publicity}
          layout.render()
          dialog.close()
          @trigger 'proposal:setting_changed'

        dialog = App.request 'dialog:new', dialogview,
          class : 'proposal-admin-status'

      @listenTo layout, 'publicity_dialog', =>
        dialogview = new Proposal.ProposalPublicityDialogView
          model : @model

        @listenTo dialogview, 'proposal:updated', (data) =>
          @model.set {access_list: data.access_list, active: data.active, publicity: data.publicity}
          layout.render()
          dialog.close()
          @trigger 'proposal:setting_changed'

        dialog = App.request 'dialog:new', dialogview,
          class : 'proposal_admin_publicity'

      @listenTo layout, 'proposal:published', (data) =>
        @model.set data.proposal.proposal
        @trigger 'proposal:published'

      @listenTo layout, 'proposal:deleted', (model) =>
        App.vent.trigger 'proposal:deleted', model
        App.navigate Routes.root_path(), {trigger : true}

    getLayout : (model) ->
      new Proposal.ProposalSettingsView
        model : @model