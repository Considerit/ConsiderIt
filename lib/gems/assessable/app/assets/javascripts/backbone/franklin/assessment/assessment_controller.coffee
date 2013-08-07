@ConsiderIt.module "Franklin", (Franklin, App, Backbone, Marionette, $, _) ->

  class Franklin.AssessmentController extends App.Controllers.Base

    initialize : (options = {}) ->
      super options
      @layout = @getLayout()
      @listenTo @layout, 'show', ->
        if @options.model.assessment
          view = @getCompletedAssessment()
          @layout.assessmentRegion.show view
        else
          view = @getRequestAssessment()
          @layout.assessmentRequestRegion.show view

    getLayout : ->
      new Franklin.AssessmentLayout

    getRequestAssessment : ->
      new Franklin.AssessmentRequestView
        already_requested_assessment : @options.point.already_requested_assessment
    
    getCompletedAssessment : ->
      new Franklin.AssessmentView
        assessment : @options.point.assessment
        claims : @options.point.claims
        num_assessment_requests : @options.point.num_assessment_requests
