@ConsiderIt.module "Franklin", (Franklin, App, Backbone, Marionette, $, _) ->


  class Franklin.AssessmentLayout extends App.Views.Layout
    template : '#tpl_assessment_layout'

    regions : 
      assessmentRequestRegion : '.m-point-assessment-request'
      assessmentRegion : '.m-point-assessment'

  class Franklin.AssessmentRequestView extends App.Views.ItemView
    template : "#tpl_assessment_request"

    serializeData : ->
      already_requested_assessment : @options.already_requested_assessment

    onShow : ->
      if !@options.already_requested_assessment
        @$el.find('.m-point-assessment-requested-feedback').hide()

    events : 
      'click .m-point-assessment-request-initiate' : 'showRequestForm'
      'click .m-point-assessment-cancel-request' : 'cancelRequest'
      'ajax:success .m-point-assessment-request-form' : 'requestMade'

    showRequestForm : ->
      @$el.find('.m-point-assessment-request-initiate').hide()
      @$el.find('.m-point-assessment-request-form').show()

    cancelRequest : ->
      @$el.find('.m-point-assessment-request-form').hide()
      @$el.find('.m-point-assessment-request-initiate').show()

    requestmade : ->
      @$el.find('.m-point-assessment-requested-feedback').show()
      @$el.find('.m-point-assessment-request-form').remove()


  class Franklin.AssessmentView extends App.Views.ItemView
    template : "#tpl_assessment"

    initialize : (options = {} ) ->
      @claims = options.claims
      @assessment = options.assessment

    serializeData : ->
      assessment : @assessment
      claims : @claims
      num_assessment_requests : @options.num_assessment_requests

    templateHelpers: 
      format_assessment_verdict : (verdict) ->
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







