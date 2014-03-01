@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->

  class Proposal.DecisionBoardLayout extends App.Views.StatefulLayout
    template : '#tpl_decision_board_layout'
    className : 'decision_board_layout' 
    regions : 
      headerRegion : '.decision_board_heading_region'
      reasonsRegion : '.decision_board_points_region'
      stanceRegion : '.slider_region'
      # explanationRegion : '.position-explanation-region'
      footerRegion : '.decision_board_footer_region'

    serializeData : ->
      tenant = App.request 'tenant'
      _.extend {}, tenant.attributes, _.compactObject(@options.proposal.attributes)


    onRender : ->
      super

      @processWhetherPointsHaveBeenIncluded()

      @$el.droppable
        accept: ".community_point .point_content"
        drop : (ev, ui) =>
          valence = if ui.draggable.parent().is('.pro') then 'pro' else 'con'
          @trigger 'point:include', ui.draggable.parent().data('id')
          @$el.removeClass "user_is_hovering_on_a_drop_target_#{valence} user_is_dragging_a_#{valence}"

        out : (ev, ui) =>
          valence = if ui.draggable.parent().is('.pro') then 'pro' else 'con'
          @$el.removeClass "user_is_hovering_on_a_drop_target_#{valence}"

        over : (ev, ui) =>
          valence = if ui.draggable.parent().is('.pro') then 'pro' else 'con'
          @$el.addClass "user_is_hovering_on_a_drop_target_#{valence}"

        activate : (ev, ui) =>
          valence = if ui.draggable.parent().is('.pro') then 'pro' else 'con'
          @$el.addClass "user_is_dragging_a_#{valence}"

        deactivate : (ev, ui) =>
          valence = if ui.draggable.parent().is('.pro') then 'pro' else 'con'
          @$el.removeClass "user_is_dragging_a_#{valence}"

    processWhetherPointsHaveBeenIncluded : ->
      if @model.getIncludedPoints().length > 0 
        @$el.removeClass 'no_included_points'
        @$el.addClass 'has_included_points'
      else
        @$el.addClass 'no_included_points'
        @$el.removeClass 'has_included_points'


  class Proposal.DecisionBoardFooterView extends App.Views.ItemView
    template : '#tpl_decision_board_footer'
    className : 'decision_board_footer_view'

    serializeData : ->
      current_user = App.request 'user:current'
      proposal = @model.getProposal()
      _.extend {},
        active : proposal.get 'active'
        updating : @model && @model.get 'published'
        follows : current_user.isFollowing 'Proposal', proposal.get('id')

    events : 
      'click [action="submit-opinion"]' : 'handleSubmitOpinion'
      'click [action="show-results"]' : 'handleCanceled'

    handleSubmitOpinion : (ev) ->
      @trigger 'opinion:submit_requested', @$el.find('#follow_proposal').is(':checked')

    handleCanceled : (ev) ->
      @trigger 'opinion:canceled'
      ev.stopPropagation()

  class Proposal.DecisionBoardHeading extends App.Views.ItemView
    template : '#tpl_decision_board_heading_view'
    className : 'decision_board_heading_view'

    serializeData : ->
      current_user = App.request 'user:current'

      if @model && @model.get('published') 
        call = 'Update your opinion' 
      else if @model.getProposal().num_participants() > 0
        call = 'Add your opinion'
      else
        call = 'Be the first to add an opinion'

      _.extend {}, @model.getProposal().attributes,
        active : @model.getProposal().get 'active'
        updating : @model && @model.get 'published'
        call : call

  class Proposal.DecisionBoardPointsLayout extends App.Views.Layout
    template : '#tpl_decision_board_points_area'
    className : 'decision_board_points_layout'

    regions : 
      decisionBoardProsRegion : '.pros_on_decision_board_region'
      decisionBoardConsRegion : '.cons_on_decision_board_region'

  class Proposal.DecisionBoardSlider extends App.Views.ItemView
    template : '#tpl_decision_board_slider'
    className : 'decision_board_slider'

    serializeData : ->
      tenant = App.request 'tenant'
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
      neutral_label : '.neutral_slider_label'
      support_label : '.supporting_slider_label'
      oppose_label : '.opposing_slider_label'

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
        behaviour: 'extend-tap'
        slide : =>
          @onSliderChange @ui.slider.val()

      @ui.slider.noUiSlider params

      is_neutral = Math.abs(@_stance_val()) < 5
      if !is_neutral
        @ui.neutral_label.css 'visibility', 'hidden'

      # initial state
      @onSliderChange @ui.slider.val()


    onSliderChange : (new_value) -> 
      return unless isFinite(new_value)

      if Math.abs(new_value) < 5
        @ui.neutral_label.css
          visibility: ''
        @is_neutral = true
      else if @is_neutral
        @ui.neutral_label.css
          visibility: 'hidden'
        @is_neutral = false

      @value = new_value

      @model.set('stance', -@value / 100, {silent : true})

      size = @slider.max_effect / 100 * @value

      @ui.oppose_label.css('font-size', 100 + size + '%')
      @ui.support_label.css('font-size', 100 - size + '%')


  # class Proposal.SummativeExplanation extends App.Views.ItemView
  #   template : '#tpl_position_explanation'
  #   className : 'position_statement'

  #   onRender : ->
  #     @stickit()

  #   bindings : 
  #     'textarea[name="explanation"]' : 'explanation'