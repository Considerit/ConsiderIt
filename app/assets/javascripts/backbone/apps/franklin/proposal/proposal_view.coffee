@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->
  
  class Proposal.ProposalDescriptionView extends App.Views.ItemView
    template : '#tpl_proposal_description'
    className : 'm-proposal-description-wrap'

    show_details : true

    editable : =>
      App.request 'auth:can_edit_proposal', @model    

    serializeData : ->
      user = @model.getUser()
      _.extend {}, @model.attributes,
        avatar : App.request('user:avatar', user, 'large' )
        description_detail_fields : @model.description_detail_fields()
        show_details : @show_details

    initialize : ->
      if @editable()
        if !Proposal.ProposalDescriptionView.editable_fields
          fields = [
            ['.m-proposal-description-title', 'name', 'textarea'], 
            ['.m-proposal-description-body', 'description', 'textarea'] ]

          editable_fields = _.union fields,
            ([".m-proposal-description-detail-field-#{f}", f, 'textarea'] for f in App.request('proposal:description_fields'))          

          Proposal.ProposalDescriptionView.editable_fields = editable_fields

        @editable_fields = Proposal.ProposalDescriptionView.editable_fields

    onRender : ->
      @stickit()
      _.each @editable_fields, (field) =>
        [selector, name, type] = field 

        @$el.find(selector).editable
          resource: 'proposal'
          pk: @long_id
          disabled: @state == 0 && @model.get('published')
          url: Routes.proposal_path @model.long_id
          type: type
          name: name
          success : (response, new_value) => @model.set(name, new_value)

    onShow : ->


    bindings : 
      '.m-proposal-description-title' : 
        observe : ['name', 'description']
        onGet : (values) -> @model.title()
      '.m-proposal-description-body' : 
        observe : 'description'
        updateMethod: 'html'
        onGet : (value) => htmlFormat(value)

    events : 
      'click .hidden' : 'showDetails'
      'click .showing' : 'hideDetails'      

    showDetails : (ev) ->
      $block = $(ev.currentTarget).closest('.m-proposal-description-detail-field')

      $block.find('.m-proposal-description-detail-field-full').slideDown();
      $block.find('.hidden')
        .text('hide')
        .toggleClass('hidden showing');

      ev.stopPropagation()

    hideDetails : (ev) ->
      $block = $(ev.currentTarget).closest('.m-proposal-description-detail-field')

      if $(document).scrollTop() > $block.offset().top
        $('body').animate {scrollTop: $block.offset().top}, 1000

      $block.find('.m-proposal-description-detail-field-full').slideUp(1000);
      $block.find('.showing')
        .text('show')
        .toggleClass('hidden showing');

      ev.stopPropagation()

  class Proposal.PositionProposalDescription extends Proposal.ProposalDescriptionView

  class Proposal.AggregateProposalDescription extends Proposal.ProposalDescriptionView

  ##############################################
  #### ProposalSummaryView
  ##############################################

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

  class Proposal.UnpublishedProposalDescription extends Proposal.ProposalDescriptionView


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

  ##############################################
