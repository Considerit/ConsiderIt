#TODO: make sure that list view kept in sync with updated assessment
@ConsiderIt.module "Dash.Admin.Assessment", (Assessment, App, Backbone, Marionette, $, _) ->

  class Assessment.EditLayout extends App.Dash.View
    dash_name : 'assess_edit_layout'
    regions : 
      contextRegion : '#context-region'
      requestsRegion : '#requests-region'
      claimsRegion : '#claims-region'
      footerRegion : '#assessment-footer-region'

    serializeData : ->
      @model.attributes

  class Assessment.ContextView extends App.Views.ItemView
    template : '#tpl_assess_edit_context'

    serializeData : ->
      assessable = @model.getAssessable()
      _.extend {}, @model.attributes,
        root_object : @model.getRoot().attributes
        assessable : assessable.attributes
        author : assessable.getUser()

    events : 
      'click .email_author' : 'emailAuthor'

    emailAuthor : (ev) ->
      @trigger 'email:author'

  class Assessment.RequestView extends App.Views.ItemView
    template : '#tpl_assess_request'
    className : 'request'
    tagName : 'div'

    serializeData : ->
      _.extend {}, @model.attributes,
        requester : App.request('user', @model.get('user_id'))

    events : 
      'click .email_requester' : 'emailRequester'

    emailRequester : (ev) ->
      @trigger 'email:requester'

  class Assessment.RequestsView extends App.Views.CollectionView
    className : 'assessment-requests'
    itemView : Assessment.RequestView


  class Assessment.ClaimListItem extends App.Views.ItemView
    template: '#tpl_claim'
    tagName: 'li'
    className : 'claim'

    initialize : (options = {}) ->
      super options
      @listenTo @model, 'change', =>
        @render()

    serializeData : ->
      params = _.extend {}, @model.attributes, 
        assessment : @model.getAssessment()
        creator : @model.getCreator()
        approver : @model.getApprover()
        format_verdict : @model.format_verdict()
        is_creator : @model.getCreator().id == App.request('user:current').id
        params


    onShow : ->
      @$el.find('.autosize').autosize()

    events : 
      'click .answer' : 'editRequested'
      'click .delete' : 'claimDeleteRequest'
      'click .approve' : 'claimApproved'

    editRequested : (ev) ->
      @trigger 'claim:edit'

    claimDeleteRequest : (ev) ->    
      if confirm('Are you sure you want to delete this?')
        @trigger 'claim:delete'

    claimApproved : (ev) ->
      @trigger 'claim:approved'

  class Assessment.ClaimsView extends App.Views.CompositeView
    template: '#tpl_claims_list'
    itemView : Assessment.ClaimListItem
    itemViewContainer : 'ul' 

    events : 
      'click .add_claim' : 'addNewClaim'

    serializeData : ->
      assessment : @options.assessment.attributes

    addNewClaim : (ev) ->
      @trigger 'claim:new'


  class Assessment.EditClaimForm extends App.Views.ItemView
    template: '#tpl_edit_claim_form'
    className: 'claim_form'

    dialog:
      title : 'Research and Evaluate Claim'

    serializeData : ->
      params = _.extend {}, @model.attributes,
        assessment : @model.getAssessment().attributes
      params

    onShow : ->
      @$el.find('textarea').autosize()
      document.getElementById("verdict_#{@model.format_verdict().toLowerCase()}").checked = true if @model.get('verdict')

    events : 
      'click .save_claim' : 'updateClaim'

    updateClaim : (ev) ->
      attrs = 
        claim_restatement : @$el.find('.claim-restatement textarea').val()
        verdict : @$el.find('.radio_block input:checked').val()
        result : @$el.find('.assessment_block textarea').val()
        notes : @$el.find('.private_note_block textarea').val()

      @trigger 'claim:updated', attrs


  class Assessment.ClaimForm extends App.Views.ItemView  
    template: '#tpl_claim_form'
    className: 'claim_form'
    dialog:
      title : 'Create new claim'

    serializeData : ->
      _.extend {}, @options.assessment.attributes,
        all_claims : @options.all_claims
        assessable: @options.assessment.getAssessable()

    events : 
      'click .create_new_claim' : 'createNewClaim'
      'click .copy_new_claim' : 'copyNewClaim'

    createNewClaim : (ev) ->
      attrs = 
        claim_restatement : @$el.find('.claim-restatement textarea').val()

      @trigger 'claim:create', attrs

    copyNewClaim : (ev) ->
      attrs = 
        copy_id : @$el.find('#other_claims select').val()
        copy : true
      
      @trigger 'claim:create', attrs


  class Assessment.EditFormsView extends App.Views.ItemView
    template : '#tpl_assess_edit_forms'

    serializeData : ->
      current_user = ConsiderIt.request 'user:current'
      can_publish = @model.allClaimsApproved()

      if can_publish
        submit_text = if @model.getClaims().length == 0 then 'Correct, there are no verifiable claims, publish it' else 'Publish fact check'
      else
        submit_text = "Can't publish until all claims approved"

      params = _.extend {}, @model.attributes, 
        assessable : @model.getAssessable().attributes
        can_publish : can_publish
        current_user : current_user.id
        submit_text : submit_text

      params 

    onShow : ->
      num_claims = @model.claims.length
      num_answered_claims = @model.claims.filter((clm) -> clm.get('verdict')? ).length

      if num_claims > 0 && num_answered_claims != num_claims
        @$el.find('.complete, #evaluate .review').hide()

    events :
      'click .publish' : 'publish'

    publish : (ev) ->
      @trigger 'publish'

  class Assessment.EmailDialogView extends App.Dash.EmailDialogView
    dialog: 
      title: "Emailing author..."
