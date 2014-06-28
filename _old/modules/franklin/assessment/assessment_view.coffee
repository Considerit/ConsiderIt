@ConsiderIt.module "Franklin.Assessment", (Assessment, App, Backbone, Marionette, $, _) ->

  class Assessment.AssessmentLayout extends App.Views.Layout
    template : '#tpl_assessment_layout'

    regions : 
      assessmentRequestRegion : '.point-assessment-request'
      assessmentRegion : '.point-assessment'


  class Assessment.AssessmentRequestView extends App.Views.ItemView
    template : "#tpl_assessment_request"

    serializeData : ->
      current_user = App.request 'user:current'
      _.extend {}, 
        already_requested_assessment : App.request 'assessment:request:by_user', @options.assessable.id, current_user.id 

    events : 
      'click .point-assessment-request-initiate' : 'showRequestForm'

    showRequestForm : (ev) ->
      @trigger 'assessment:request'


  class Assessment.AssessmentRequestFormView extends App.Views.ItemView
    template : "#tpl_assessment_request_form"
    dialog:
      title : 'Ask a librarian about this point'

    serializeData : ->
      current_user = App.request 'user:current'
      _.extend {}, 
        assessable : @options.assessable

    onShow : ->
      $textarea = @$el.find('textarea')
      $textarea.autosize()
      $textarea.focus()

    events : 
      'click input[type="submit"]' : 'createRequest'

    createRequest : (ev) ->
      attrs = 
        suggestion : @$el.find('#request_suggestion').val()
      @trigger 'assessment:request:create', attrs


  class Assessment.AssessmentHeaderView extends App.Views.ItemView
    template : "#tpl_assessment_header"
    className : 'assessment-header'

    serializeData : ->
      params = 
        assessment : @model.attributes
        claims : @options.claims
      params