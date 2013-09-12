@ConsiderIt.module "Franklin.Assessment", (Assessment, App, Backbone, Marionette, $, _) ->

  class Assessment.AssessmentLayout extends App.Views.Layout
    template : '#tpl_assessment_layout'

    regions : 
      assessmentRequestRegion : '.m-point-assessment-request'
      assessmentRegion : '.m-point-assessment'


  class Assessment.AssessmentRequestView extends App.Views.ItemView
    template : "#tpl_assessment_request"

    serializeData : ->
      current_user = App.request 'user:current'
      _.extend {}, 
        already_requested_assessment : App.request 'assessment:request:by_user', current_user.id 
        assessable : @options.assessable

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


  class Assessment.AssessmentView extends App.Views.ItemView
    template : "#tpl_assessment"

    serializeData : ->
      params = 
        assessment : @model.attributes
        claims : @options.claims
        num_assessment_requests : @options.assessable.get('num_assessment_requests')
      params