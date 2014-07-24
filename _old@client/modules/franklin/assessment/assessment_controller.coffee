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
          @listenTo view, 'show', =>
            @listenTo view, 'assessment:request', =>
              request_view = @getRequestForm()
              @listenTo request_view, 'show', =>
                @listenTo request_view, 'assessment:request:create', (attrs) =>
                  _.extend attrs,
                    assessable_id : @options.assessable.id
                    assessable_type : 'Point'

                  rq = App.request 'assessment:request:create', attrs
                  App.execute 'when:fetched', rq, =>
                    toastr.success 'Fact-check request successful. You\'ll hear back soon.'
                    request_view.close()
                    view.render()

              overlay = @getOverlay request_view

          @layout.assessmentRequestRegion.show view

      @region.show @layout

    close : ->
      @layout.close()
      super

    getLayout : ->
      new Assessment.AssessmentLayout

    getRequestAssessment : ->
      new Assessment.AssessmentRequestView
        model : @options.model
        assessable : @options.assessable

    getRequestForm : ->
      new Assessment.AssessmentRequestFormView
        model : @options.model
        assessable : @options.assessable

    getCompletedAssessment : ->
      new Assessment.AssessmentHeaderView
        model : @options.model
        claims : @options.model.getClaims()
        assessable : @options.assessable

    getOverlay : (view) ->
      App.request 'dialog:new', view, 
        class: 'assessment_request_form_dialog'
