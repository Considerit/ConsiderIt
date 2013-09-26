@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->
  
  class Proposal.UnpublishedProposalDescription extends Proposal.ProposalDescriptionView

  class Proposal.ProposalSummaryView extends App.Views.Layout
    template : '#tpl_proposal_summary'
    tagName: 'li'
    className : 'm-proposal'
    attributes : ->
      "data-role": 'm-proposal'
      "data-id": "#{@model.id}"
      
    regions : 
      summaryRegion : '.m-results-summary-region'
      proposalRegion : '.m-proposal-description-region'

    initialize : (options = {}) ->


    serializeData : ->
      user_position = @model.getUserPosition()

      params = _.extend {}, @model.attributes, 
        call : if user_position && user_position.get('published') then 'Update your position' else 'What do you think?'
      params

    onRender : ->
      @$el.attr('data-state', 0)
      @$el.attr('data-visibility', 'unpublished') if !@model.get 'published'


  class Proposal.SummaryProposalDescription extends Proposal.ProposalDescriptionView
    show_details : false
  
    editable : => false

    initialize : (options = {}) ->
      super options
      _.extend @events, 
        'click .m-proposal-description' : 'toggleDescription'

    toggleDescription : (ev) ->
      @trigger 'proposal:clicked'


  class Proposal.SummaryResultsView extends App.Views.ItemView

    template : '#tpl_proposal_summary_results'

    serializeData : ->
      top_pro = App.request 'point:get', @model.get('top_pro')
      top_con = App.request 'point:get', @model.get('top_con')

      top_pro = null if !top_pro.id
      top_con = null if !top_con.id

      tenant = App.request 'tenant:get'
      participants = @model.getParticipants()
      
      params = _.extend {}, @model.attributes, 
        top_pro : if top_pro then top_pro.attributes else null
        top_con : if top_con then top_con.attributes else null
        top_pro_user : if top_pro then top_pro.getUser().attributes else null
        top_con_user : if top_con then top_con.getUser().attributes else null
        pro_label : tenant.getProLabel()
        con_label : tenant.getConLabel()
        participants : _.sortBy(participants, (user) -> !user.get('avatar_file_name')?  )
        tile_size : @getTileSize()

      params

    getTileSize : ->
      PARTICIPANT_WIDTH = 150
      PARTICIPANT_HEIGHT = 110

      Math.min 50, 
        window.getTileSize(PARTICIPANT_WIDTH, PARTICIPANT_HEIGHT, @model.getParticipants().length)

    onShow : ->


  class Proposal.ModifiableProposalSummaryView extends Proposal.ProposalSummaryView
    admin_template : '#tpl_proposal_admin_strip'

    initialize : (options = {} ) ->
      super options

    onShow : (options = {}) ->
      #super options
      if !Proposal.ModifiableProposalSummaryView.compiled_admin_template?
        Proposal.ModifiableProposalSummaryView.compiled_admin_template = _.template($(@admin_template).html())

      params = _.extend {}, @model.attributes
      @$admin_el = Proposal.ModifiableProposalSummaryView.compiled_admin_template params
      @$el.append @$admin_el


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
        toastr.success 'Published!'
      else
        toastr.error 'Failed to publish'

      @trigger 'proposal:published', data.proposal.proposal, data.position.position

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

    changeSettings : (ev, response ,options) ->
      data = $.parseJSON response.responseText
      @trigger 'proposal:updated', data

