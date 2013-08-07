class ConsiderIt.AssessmentView extends Backbone.View

  tagName : 'li'
  assessment_template : "#tpl_assessment"
  request_template : "#tpl_assessment_request"

  initialize : (options) -> 
    @proposal = options.proposal

  render : () -> 
    if @model.assessment 

      @$el.html @assessment_template($.extend({}, @model.attributes, {
          user : ConsiderIt.users[@model.get('user_id')]
          proposal : @proposal.attributes
          assessment : @model.assessment
          claims : @model.claims
          num_assessment_requests : @model.num_assessment_requests
          format_verdict : ConsiderIt.AssessmentView.format_assessment_verdict
        }))
    
    else
      @$el.html @request_template($.extend({}, @model.attributes, {
          proposal : @proposal.attributes
          already_requested_assessment : @model.already_requested_assessment

        }))
      if !@model.already_requested_assessment
        @$el.find('.m-point-assessment-requested-feedback').hide()

    #TODO: if user logs in as admin, need to do this
    # if ConsiderIt.request('user:current').id == @model.get('user_id') || ConsiderIt.request('user:current').is_admin() || ConsiderIt.request('user:current').is_evaluator()
    #   @$el.find('.m-comment-body').editable {
    #       resource: 'comment'
    #       pk: @model.id
    #       url: Routes.update_comment_path @model.id
    #       type: 'textarea'
    #       name: 'body'
    #     }

    this

  events : 
    'click .m-point-assessment-request-initiate' : 'show_request_form'
    'click .m-point-assessment-cancel-request' : 'cancel_request'
    'ajax:success .m-point-assessment-request-form' : 'request_handled'

  show_request_form : ->
    @$el.find('.m-point-assessment-request-initiate').hide()
    @$el.find('.m-point-assessment-request-form').show()

  cancel_request : ->
    @$el.find('.m-point-assessment-request-form').hide()
    @$el.find('.m-point-assessment-request-initiate').show()

  request_handled : ->
    @$el.find('.m-point-assessment-requested-feedback').show()
    @$el.find('.m-point-assessment-request-form').remove()

  @format_assessment_verdict : (verdict) ->
    if verdict == 2
      'Accurate'
    else if verdict == 1
      'Unverifiable'
    else if verdict == 0
      'Questionable'
    else if verdict == -1
      'No checkable claims'
    else
      '-'
