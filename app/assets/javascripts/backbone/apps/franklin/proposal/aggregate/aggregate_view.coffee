@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->


  class Proposal.AggregateLayout extends App.Views.StatefulLayout
    template : '#tpl_aggregate_layout'
    className : 'm-results'
      
    regions : 
      histogramRegion : '.m-histogram-region'
      #socialMediaRegion : '.m-proposal-socialmedia-region'

    initialize : (options = {}) ->
      super options    

    serializeData : ->
      _.extend {}, @model.attributes



  class Proposal.AggregateHistogram extends App.Views.ItemView
    template : '#tpl_aggregate_histogram'
    className : 'm-histogram'
    bar_state : null
    highlight_state : []

    serializeData : ->

      supporter_label = @model.get('slider_left') || 'Supporters'
      opposer_label = @model.get('slider_right') || 'Opposers'
      neutral_label = @model.get('slider_middle') || 'Neutral / Undecided'

      _.extend {}, @model.attributes,
        histogram : @options.histogram
        supporter_label : supporter_label
        opposer_label : opposer_label
        neutral_label : neutral_label

    events : 
      'mouseenter .m-histogram-bar:not(.m-bar-is-selected)' : 'selectBar'
      'click .m-histogram-bar:not(.m-bar-is-hard-selected)' : 'selectBar'
      'click .m-bar-is-hard-selected' : 'deselectBar'
      'mouseleave .m-histogram-bar' : 'deselectBar'
      'keypress' : 'deselectBar'
      'mouseenter .m-histogram-bar:not(.m-bar-is-hard-selected) [data-target="user_profile_page"]' : 'preventProfile'

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

    finishSelectingBar : (bucket, hard_select) ->
      $bar = @$el.find(".m-histogram-bar[bucket=#{6-bucket}]")

      @$el.addClass 'm-histogram-segment-selected'

      @$el.hide()

      $('.m-bar-is-selected', @$el).removeClass('m-bar-is-selected m-bar-is-hard-selected m-bar-is-soft-selected')
      $bar.addClass("m-bar-is-selected #{if hard_select then 'm-bar-is-hard-selected' else 'm-bar-is-soft-selected'}")

      fld = "score_stance_group_#{bucket}"

      @$el.find('.l-message-speaker').css('z-index': 999)

      #######
      # when clicking outside of bar, close it
      if hard_select
        $(document).on 'click.histogram', (ev) => @closeBarClick(ev)
        $(document).on 'keyup.histogram', (ev) => @closeBarKey(ev)
      #######

      @$el.show()

    selectBar : (ev) ->
      return if $('.m-point-expanded').length > 0 #|| @state != Proposal.ReasonsState.together 
      $target = $(ev.currentTarget)
      hard_select = ev.type == 'click'

      if ( hard_select || @$el.find('.m-bar-is-hard-selected').length == 0 )
        $bar = $target.closest('.m-histogram-bar')

        bucket = 6 - $target.closest('.m-histogram-bar').attr('bucket')

        @trigger 'histogram:segment_results', bucket, hard_select

      if hard_select
        ev.stopPropagation()

      @bar_state = 'select'

    closeBarClick : (ev) -> @deselectBar() 

    closeBarKey : (ev) -> @deselectBar() if ev.keyCode == 27 && $('#l-dialog-detachable').children().length == 0 && $('.m-point-expanded').length == 0
    
    deselectBar : (ev) ->
      $selected_bar = @$el.find('.m-bar-is-selected')
      return if $selected_bar.length == 0 || (ev && ev.type == 'mouseleave' && $selected_bar.is('.m-bar-is-hard-selected')) || $('.m-point-expanded').length > 0

      @bar_state = 'deselect'
      $(document).off 'click.histogram'
      $(document).off 'keyup.histogram'

      # this slight delay helps to prevent rerendering when moving mouse in between histogram bars
      _.delay =>
        if @bar_state == 'deselect'
          @$el.hide()

          @$el.removeClass 'm-histogram-segment-selected'

          hiding = @$el.find('.m-point-list, .m-results-pro-con-list-who')
          hiding.css 'visibility', 'hidden'

          @trigger 'histogram:segment_results', 'all'

          @$el.find('.l-message-speaker').css('z-index': '')

          hiding.css 'visibility', ''

          $selected_bar.removeClass('m-bar-is-selected m-bar-is-hard-selected m-bar-is-soft-selected')

          @$el.show()
      , 100




