@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->

  class Proposal.HistogramLayout extends App.Views.StatefulLayout
    template : '#tpl_histogram_layout'
    className : 'histogram_layout'
    bar_state : null
    highlight_state : []
    histogram: null

    setHistogram : (histogram) ->
      @histogram = histogram
      @render()

    serializeData : ->

      supporter_label = @model.get('slider_left') || 'Supporters'
      opposer_label = @model.get('slider_right') || 'Opposers'
      neutral_label = @model.get('slider_middle') || 'Neutral / Undecided'

      _.extend {}, @model.attributes,
        histogram : @histogram
        supporter_label : supporter_label
        opposer_label : opposer_label
        neutral_label : neutral_label

    events : 
      'mouseenter .histogram_bar:not(.bar_is_selected)' : 'selectBar'
      'click .histogram_bar:not(.bar_is_hard_selected)' : 'selectBar'
      'click .bar_is_hard_selected' : 'deselectBar'
      'mouseleave .histogram_bar' : 'deselectBar'
      'keypress' : 'deselectBar'
      'mouseenter .histogram_bar:not(.bar_is_hard_selected) [data-tooltip="user_profile"]' : 'preventProfile'

    preventProfile : (ev) ->
      ev.stopPropagation()
      $(ev.currentTarget).parent().trigger('mouseenter')

    highlightUsers : (users, highlight = true) ->

      if Modernizr.opacity
        selector = ("#avatar-#{uid}" for uid in users).join(',')

        @$el.hide()

        if highlight
          if @highlight_state.length > 0
            restore_opacity = ("#avatar-#{uid}" for uid in @highlight_state).join(',')
            @$el.find(".avatar:not(#{restore_opacity})").css 
              opacity: ''
            @highlight_state = []

          @$el.find(".avatar:not(#{selector})").css
            opacity: 0

        else
          @highlight_state = _.union users, @highlight_state
          # this delay is a performance enhancement for skipping unhighlight when unnecessary
          _.delay =>
            if @highlight_state.length > 0
              restore_opacity = ("#avatar-#{uid}" for uid in @highlight_state).join(',')
              @$el.find(".avatar:not(#{restore_opacity})").css 
                opacity: ''

              @highlight_state = []
          , 50

        @$el.show()

    finishSelectingBar : (segment, hard_select) ->
      $bar = @$el.find(".histogram_bar[segment=#{6-segment}]")

      # @$el.addClass 'histogram-segment-selected'

      @$el.hide()

      $('.bar_is_selected', @$el).removeClass('bar_is_selected bar_is_hard_selected bar_is_soft_selected')
      $bar.addClass("bar_is_selected #{if hard_select then 'bar_is_hard_selected' else 'bar_is_soft_selected'}")

      fld = "score_stance_group_#{segment}"

      #######
      # when clicking outside of bar, close it
      if hard_select
        $(document).on 'click.histogram', (ev) => @closeBarClick(ev)
        $(document).on 'keyup.histogram', (ev) => @closeBarKey(ev)
      #######

      @$el.show()

    selectBar : (ev) ->
      return if $('.open_point').length > 0 #|| @state != Proposal.State.Results 
      $target = $(ev.currentTarget)
      hard_select = ev.type == 'click'

      if ( hard_select || @$el.find('.bar_is_hard_selected').length == 0 )
        $bar = $target.closest('.histogram_bar')
        segment = 6 - $target.closest('.histogram_bar').attr('segment')
        @trigger 'histogram:segment_results', segment, hard_select

      if hard_select
        ev.stopPropagation()

      @bar_state = 'select'

    closeBarClick : (ev) -> @deselectBar() 

    closeBarKey : (ev) -> @deselectBar() if ev.keyCode == 27 && $('.l-dialog-detachable').children().length == 0 && $('.open_point').length == 0
    
    deselectBar : (ev) ->
      $selected_bar = @$el.find('.bar_is_selected')
      return if $selected_bar.length == 0 || (ev && ev.type == 'mouseleave' && $selected_bar.is('.bar_is_hard_selected')) || $('.open_point').length > 0

      @bar_state = 'deselect'
      $(document).off 'click.histogram'
      $(document).off 'keyup.histogram'

      # this slight delay helps to prevent rerendering when moving mouse in between histogram bars
      _.delay =>
        if @bar_state == 'deselect'
          @$el.hide()

          # @$el.removeClass 'histogram-segment-selected'

          hiding = @$el.find('.point_list_collectionview, .results-pro-con-list-who')
          hiding.css 'visibility', 'hidden'

          @trigger 'histogram:segment_results', 'all'

          hiding.css 'visibility', ''

          $selected_bar.removeClass('bar_is_selected bar_is_hard_selected bar_is_soft_selected')

          @$el.show()
      , 100




