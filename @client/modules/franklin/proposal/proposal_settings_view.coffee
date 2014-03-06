@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->

  class Proposal.ProposalSettingsView extends App.Views.ItemView
    template : '#tpl_proposal_admin_strip'

    serializeData : ->
      @model.attributes

    events : 
      'ajax:complete .delete_proposal' : 'deleteProposal'
      'click .proposal_admin_operations_status' : 'showStatus'
      'click .proposal-admin_operations-publicity' : 'showPublicity'
      'ajax:complete .proposal_publish-form' : 'publishProposal'

    showStatus : (ev) ->
      @trigger 'status_dialog'

    showPublicity : (ev) ->
      @trigger 'publicity_dialog'

    deleteProposal : (ev, response, options) ->
      data = $.parseJSON(response.responseText)
      if data.success
        @trigger 'proposal:deleted', @model
        toastr.success 'Successfully deleted'
      else
        toastr.error 'Failed to delete'

    publishProposal : (ev, response, options) ->
      data = $.parseJSON response.responseText
      if data.success
        toastr.success 'Published! Start the conversation with some pro/con points of your own if appropriate.', null,
          positionClass: "toast-top-full-width"
      else
        toastr.error 'Failed to publish'

      @trigger 'proposal:published', data

  class Proposal.ProposalStatusDialogView extends App.Views.ItemView
    template : '#tpl_proposal_admin_strip_edit_active'

    dialog:
      title : 'Set the status of this proposal.'

    serializeData : ->
      _.extend {}, @model.attributes

    events : 
      'ajax:complete .proposal_admin_operations_settings_form' : 'changeSettings'

    changeSettings : (ev, response, options) ->
      data = $.parseJSON(response.responseText)
      @trigger 'proposal:updated', data

  class Proposal.ProposalPublicityDialogView extends App.Views.ItemView
    template : '#tpl_proposal_admin_strip_edit_publicity'

    dialog:
      title : 'Who can view and participate?'

    serializeData : ->
      _.extend {}, @model.attributes

    events : 
      'ajax:complete .proposal_admin_operations_settings_form' : 'changeSettings'
      'click [name="proposal[access_list]"]' : 'selectPrivate'

    changeSettings : (ev, response ,options) ->
      data = $.parseJSON response.responseText
      @trigger 'proposal:updated', data

    selectPrivate : (ev) ->
      @$el.find('#proposal_publicity_0').prop 'checked', 'checked'

    onRender : ->
      $access_list = @$el.find('[name="proposal[access_list]"]')
      $access_list.val @model.get('access_list')
      $access_list.autosize()
