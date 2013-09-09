@ConsiderIt.module "Franklin.Assessment", (Assessment, App, Backbone, Marionette, $, _) ->

  class Assessment.AssessmentController extends App.Controllers.Base

    initialize : (options = {}) ->
      @layout = @getLayout()
      @listenTo @layout, 'show', ->
        if @options.model
          view = @getCompletedAssessment()
          @layout.assessmentRegion.show view
        else if @options.assessable.getProposal().get('active') 
          view = @getRequestAssessment()
          @layout.assessmentRequestRegion.show view

      @region.show @layout

    getLayout : ->
      new Assessment.AssessmentLayout

    getRequestAssessment : ->
      new Assessment.AssessmentRequestView
        model : @options.model
        assessable : @options.assessable

    getCompletedAssessment : ->
      new Assessment.AssessmentView
        model : @options.model
        claims : @options.model.getClaims()
        assessable : @options.assessable
