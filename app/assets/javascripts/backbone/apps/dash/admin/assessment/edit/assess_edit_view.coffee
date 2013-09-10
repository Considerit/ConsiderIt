#TODO: make sure that list view kept in sync with updated assessment
@ConsiderIt.module "Dash.Admin.Assessment", (Assessment, App, Backbone, Marionette, $, _) ->

  class Assessment.EditLayout extends App.Dash.View
    dash_name : 'assess_edit_layout'
    regions : 
      contextRegion : '#to_be_checked'
      requestsRegion : '#requester_sidebar'
      claimsRegion : '#claims'
      formRegion : '#evaluate'

  class Assessment.EditContextView extends App.Views.ItemView
    template : '#tpl_assess_edit_context'

    serializeData : ->
      _.extend {}, @model.attributes,
        root_object : @model.getRoot().attributes
        assessable : @model.getAssessable().attributes

  class Assessment.RequestView extends App.Views.ItemView
    template : '#tpl_assess_request'
    className : 'request'
    tagName : 'div'

    serializeData : ->
      _.extend {}, @model.attributes,
        user_name : App.request('user', @model.get('user_id')).get('name')

  class Assessment.RequestsView extends App.Views.CollectionView
    template: '#tpl_assess_edit_requesters'
    itemView : Assessment.RequestView
    itemViewContainer : '.requests'


  class Assessment.ClaimListItem extends App.Views.ItemView
    template: '#tpl_claim'
    tagName: 'li'
    className : 'claim'

    serializeData : ->
      _.extend {}, @model.attributes, 
        assessment : @model.getAssessment().attributes
        format_verdict : @model.format_verdict()

    onShow : ->
      @$el.find('.autosize').autosize()
      @_check_box @model, null, 'claim_verdict_accurate', @model.get('verdict') == 2
      @_check_box @model, null, 'claim_verdict_unverifiable', @model.get('verdict') == 1
      @_check_box @model, null, 'claim_verdict_questionable', @model.get('verdict') == 0

    _check_box : (model, attribute, selector, condition) ->
      if condition || (!condition? && model.get(attribute))
        input = @$el.find('#' + selector).attr('checked', 'checked')

    events : 
      'click .actions .answer' : 'toggleEdit'
      'click .open .cancel' : 'toggleEdit'
      'ajax:complete .m-assessment-claim-update' : 'claimUpdated'
      'ajax:complete .m-assessment-claim-delete' : 'claimDeleted'

    toggleEdit : (ev) ->
      $claim = $(ev.currentTarget).parents('.claim')
      $claim.find('.open, .closed, .head .answer').toggleClass('hide')
      $claim.find('.autosize').trigger('keyup')

    claimUpdated : (ev, response, options) ->
      params = $.parseJSON(response.responseText).claim
      @trigger 'claim:updated', @model, params

    claimDeleted : (ev, response, options) ->
      @trigger 'claim:deleted', @model


  class Assessment.ClaimsView extends App.Views.CompositeView
    template: '#tpl_claims_list'
    itemView : Assessment.ClaimListItem
    itemViewContainer : 'ul' 

    serializeData : ->
      _.extend {}, @options.assessment.attributes,
        all_claims : @options.all_claims

    events : 
      'ajax:complete .m-assessment-create_claim' : 'createClaim'
      'click .add_claim' : 'toggleClaimForm'
      'click .add_claim_form .cancel' : 'toggleClaimForm'

    createClaim : (ev, response, options) ->
      claim = $.parseJSON(response.responseText).claim
      @trigger 'claim:created', claim

    toggleClaimForm : (ev) ->
      @$el.find('.add_claim, .add_claim_form form, .add_claim_form #other_claims').toggleClass('hide')
      @$el.find('.add_claim_form').find('.autosize').trigger('keyup')


  class Assessment.EditFormsView extends App.Views.ItemView
    template : '#tpl_assess_edit_forms'

    serializeData : ->
      current_user = ConsiderIt.request 'user:current'
      params = _.extend {}, @model.attributes, 
        assessable : @model.getAssessable().attributes
        can_publish : @model.get('reviewable') && current_user.id != @model.get('user_id')
        current_user : current_user.id

      if params.can_publish
        params.submit_text = if @model.claims.length == 0 then 'Correct, there are no verifiable claims, publish it' else 'Publish fact check'
      else if @model.get 'reviewable'
        params.submit_text = if @model.claims.length == 0 then 'There are no verifiable claims' else 'Submit for review'

      params 

    onShow : ->
      num_claims = @model.claims.length
      num_answered_claims = @model.claims.filter((clm) -> clm.get('verdict')? ).length

      if num_claims > 0 && num_answered_claims != num_claims
        @$el.find('.complete, #evaluate .review').hide()

    events :
      'ajax:complete .m-assessment-update' : 'assessmentUpdated'

    assessmentUpdated : (ev, response, options) ->
      params = $.parseJSON(response.responseText).assessment
      @trigger 'assessment:updated', params

