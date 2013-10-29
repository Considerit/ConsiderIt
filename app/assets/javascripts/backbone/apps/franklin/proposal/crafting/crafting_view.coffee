@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->

  class Proposal.PositionLayout extends App.Views.StatefulLayout
    template : '#tpl_position_crafting_layout'
    className : 'l-message m-position'
    regions : 
      reasonsRegion : '.m-position-reasons-region'
      stanceRegion : '.m-position-stance-region'
      explanationRegion : '.m-position-explanation-region'
      footerRegion : '.m-position-footer-region'

    serializeData : ->
      tenant = App.request 'tenant:get'
      _.extend {}, tenant.attributes, _.compactObject(@options.proposal.attributes)


  class Proposal.PositionFooterView extends App.Views.ItemView
    template : '#tpl_position_footer'
    className : 'm-position-footer'

    serializeData : ->
      current_user = App.request 'user:current'
      _.extend {},
        active : @model.getProposal().get 'active'
        updating : @model && @model.get 'published'
        follows : current_user.isFollowing 'Proposal', @model.id

    events : 
      'click [data-target="submit-position"]' : 'handleSubmitPosition'
      'click [data-target="show-results"]' : 'handleCanceled'

    handleSubmitPosition : (ev) ->
      @trigger 'position:submit-requested', @$el.find('#follow_proposal').is(':checked')

    handleCanceled : (ev) ->
      @trigger 'position:canceled'
      ev.stopPropagation()

  class Proposal.PositionReasonsLayout extends App.Views.Layout
    template : '#tpl_position_reasons'
    className : 'm-personal-reasons'

    regions : 
      positionProsRegion : '.m-position-propoints-region'
      positionConsRegion : '.m-position-conpoints-region'

  class Proposal.PositionStance extends App.Views.ItemView
    template : '#tpl_position_stance'
    className : 'm-stance'

    serializeData : ->
      tenant = App.request 'tenant:get'
      params = _.extend {}, tenant.attributes, _.compactObject(@options.proposal.attributes)
      params

    slider : 
      max_effect : 65 
    
    slider_ui_init : 
      handles: 1
      connect: "lower"
      range: [-100, 100]
      width: 300

    ui : 
      slider : '.noUiSlider'
      neutral_label : '.m-stance-label-neutral'
      support_label : '.m-stance-label-support'
      oppose_label : '.m-stance-label-oppose'

    _stance_val : ->
      @model.get('stance') * 100

    onShow : ->
      @bindUIElements()
      @listenTo @model, 'change:stance', => 
        @ui.slider.val -@_stance_val()

      @createSlider()

    createSlider : ->
      @value = @_stance_val()

      params = _.extend {}, @slider_ui_init, 
          start : -@_stance_val()
          slide : =>
            @sliderChange @ui.slider.val()

      @ui.slider.noUiSlider params

      is_neutral = Math.abs(@_stance_val()) < 5
      if !is_neutral
        @ui.neutral_label.css('opacity', 0)

    sliderChange : (new_value) -> 
      return unless isFinite(new_value)

      if Math.abs(new_value) < 5
        @ui.neutral_label.css('opacity', 1)
        @is_neutral = true
      else if @is_neutral
        @ui.neutral_label.css('opacity', 0)
        @is_neutral = false

      @value = new_value

      @model.set('stance', -@value / 100, {silent : true})

      size = @slider.max_effect / 100 * @value
      @ui.oppose_label.css('font-size', 100 + size + '%')
      @ui.support_label.css('font-size', 100 - size + '%')



  class Proposal.PositionExplanation extends App.Views.ItemView
    template : '#tpl_position_explanation'
    className : 'position_statement'

    onRender : ->
      @stickit()

    bindings : 
      'textarea[name="explanation"]' : 'explanation'