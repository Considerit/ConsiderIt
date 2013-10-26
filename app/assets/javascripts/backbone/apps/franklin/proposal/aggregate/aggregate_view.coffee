@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->


  class Proposal.AggregateLayout extends App.Views.StatefulLayout
    template : '#tpl_aggregate_layout'
    className : 'm-results'
      
    regions : 
      histogramRegion : '.m-histogram-region'
      #socialMediaRegion : '.m-proposal-socialmedia-region'

    initialize : (options = {}) ->
      super options

    onRender : ->
      @setDataState @state

    setDataState : (state) ->
      @$el.attr 'data-state', state
      @$el.data 'state', state
      @state = state      

    serializeData : ->
      _.extend {}, @model.attributes



  class Proposal.AggregateHistogram extends App.Views.ItemView
    template : '#tpl_aggregate_histogram'
    className : 'm-histogram'

    serializeData : ->

      supporter_label = @model.get('slider_left') || 'Supporters'
      opposer_label = @model.get('slider_right') || 'Opposers'

      _.extend {}, @model.attributes,
        histogram : @options.histogram
        supporter_label : supporter_label
        opposer_label : opposer_label

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

      selector = ("#avatar-#{uid}" for uid in users).join(',')

      @$el.css 'visibility', 'hidden'
      if highlight
        @$el.addClass 'm-histogram-segment-selected'
        @$el.find('.avatar').hide()        
        @$el.find(selector).css {'display': '', 'opacity': 1}
      else
        @$el.removeClass 'm-histogram-segment-selected'
        @$el.find('.avatar').css {'display': '', 'opacity': ''} 
      @$el.css 'visibility', ''

    selectBar : (ev) ->
      return if $('.m-point-expanded').length > 0
      $target = $(ev.currentTarget)
      hard_select = ev.type == 'click'

      if ( hard_select || @$el.find('.m-bar-is-hard-selected').length == 0 )
        @$el.addClass 'm-histogram-segment-selected'
        #@$el.find('.m-bar-percentage').hide()

        $bar = $target.closest('.m-histogram-bar')
        # bubble_offset = $bar.offset().top - @$el.closest('.l-message-body').offset().top + 20

        @$el.hide()

        bucket = 6 - $bar.attr('bucket')
        $('.m-bar-is-selected', @$el).removeClass('m-bar-is-selected m-bar-is-hard-selected m-bar-is-soft-selected')
        $bar.addClass("m-bar-is-selected #{if hard_select then 'm-bar-is-hard-selected' else 'm-bar-is-soft-selected'}")


        fld = "score_stance_group_#{bucket}"

        @trigger 'histogram:segment_results', bucket

        @$el.find('.l-message-speaker').css('z-index': 999)

        #######
        # when clicking outside of bar, close it
        if hard_select
          $(document).on 'click.histogram', (ev) => @closeBarClick(ev)
          $(document).on 'keyup.histogram', (ev) => @closeBarKey(ev)
          ev.stopPropagation()
        #######

        @$el.show()

    closeBarClick : (ev) -> @deselectBar() 

    closeBarKey : (ev) -> @deselectBar() if ev.keyCode == 27 && $('#l-dialog-detachable').children().length == 0 && $('.m-point-expanded').length == 0
    
    deselectBar : (ev) ->
      $selected_bar = @$el.find('.m-bar-is-selected')
      return if $selected_bar.length == 0 || (ev && ev.type == 'mouseleave' && $selected_bar.is('.m-bar-is-hard-selected')) || $('.m-point-expanded').length > 0

      @$el.hide()

      @$el.removeClass 'm-histogram-segment-selected'

      hiding = @$el.find('.m-point-list, .m-results-pro-con-list-who')
      hiding.css 'visibility', 'hidden'

      @trigger 'histogram:segment_results', 'all'

      @$el.find('.l-message-speaker').css('z-index': '')

      hiding.css 'visibility', ''

      $selected_bar.removeClass('m-bar-is-selected m-bar-is-hard-selected m-bar-is-soft-selected')

      $(document).off 'click.histogram'
      $(document).off 'keyup.histogram'
      @$el.show()




