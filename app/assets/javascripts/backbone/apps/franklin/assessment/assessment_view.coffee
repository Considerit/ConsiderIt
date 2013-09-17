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
        already_requested_assessment : App.request 'assessment:request:by_user', @options.assessable.id, current_user.id 

    events : 
      'click .m-point-assessment-request-initiate' : 'showRequestForm'

    showRequestForm : (ev) ->
      @trigger 'assessment:request'


  class Assessment.AssessmentRequestFormView extends App.Views.ItemView
    template : "#tpl_assessment_request_form"
    dialog:
      title : 'Request a fact check of this point'

    serializeData : ->
      current_user = App.request 'user:current'
      _.extend {}, 
        assessable : @options.assessable

    onShow : ->


    events : 
      'click input[type="submit"]' : 'createRequest'

    createRequest : (ev) ->
      attrs = 
        suggestion : @$el.find('#request_suggestion').val()
      @trigger 'assessment:request:create', attrs


  class Assessment.AssessmentView extends App.Views.ItemView
    template : "#tpl_assessment"

    serializeData : ->
      params = 
        assessment : @model.attributes
        claims : @options.claims
      params