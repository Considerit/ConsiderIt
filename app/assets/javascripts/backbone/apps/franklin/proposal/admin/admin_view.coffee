@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->

  class Proposal.AdminSettingsView extends App.Views.ItemView
    template : '#tpl_proposal_admin_strip'

    serializeData : ->
      @model.attributes

    events : 
      'ajax:complete .m-delete_proposal' : 'deleteProposal'
      'click .m-proposal-admin_operations-status' : 'showStatus'
      'click .m-proposal-admin_operations-publicity' : 'showPublicity'
      'ajax:complete .m-proposal-publish-form' : 'publishProposal'

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
      'ajax:complete .m-proposal-admin_operations-settings-form' : 'changeSettings'

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
      'ajax:complete .m-proposal-admin_operations-settings-form' : 'changeSettings'

    changeSettings : (ev, response ,options) ->
      data = $.parseJSON response.responseText
      @trigger 'proposal:updated', data

    onRender : ->
      $access_list = @$el.find('[name="proposal[access_list]"]')
      $access_list.val @model.get('access_list')
      $access_list.autosize()
