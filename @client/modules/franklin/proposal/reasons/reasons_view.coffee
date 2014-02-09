@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->

  class Proposal.ReasonsLayout extends App.Views.StatefulLayout
    template: '#tpl_reasons_layout'
    className: 'reasons'

    regions : 
      positionRegion : '.position-region'
      footerRegion : '.reasons-footer-region'      
      peerProsRegion : '.aggregated-propoints-region'
      peerConsRegion : '.aggregated-conpoints-region'
      participantsRegion : '.participants'

    initialize : (options = {}) ->
      super options

    onRender : ->
      super

    pointExpanded : (region) ->
      region.$el.css 'zIndex', 12
      $transition_speed = if Modernizr.csstransitions then 1000 else 0
      @sizeToFit $transition_speed

    pointClosed : (region) ->
      region.$el.css 'zIndex', ''
      $transition_speed = if Modernizr.csstransitions then 1000 else 0
      @sizeToFit $transition_speed

    pointsBrowsing : (valence) ->

      if valence == 'pro'
        @peerProsRegion.$el.addClass 'pointlist-browsing'
        @$el.addClass 'reasons-browsing reasons-browsing-pros'

      else
        @peerConsRegion.$el.addClass 'pointlist-browsing'
        @$el.addClass 'reasons-browsing reasons-browsing-cons'

      @sizeToFit 10

    pointsBrowsingOff : (valence) ->
      @peerConsRegion.$el.css 
        right: ''
        @positionRegion.$el.css 
          left: ''

      if valence == 'con'
        @peerProsRegion.$el.css 
          left: ''

        @peerConsRegion.$el.removeClass 'pointlist-browsing'
        @$el.removeClass 'reasons-browsing reasons-browsing-cons'

      else
        @peerProsRegion.$el.removeClass 'pointlist-browsing'
        @$el.removeClass 'reasons-browsing reasons-browsing-pros'

      @sizeToFit 10

    _sizeToFit : (minheight) ->
      $to_fit = @$el.find('.reasons-lists')

      $to_fit.css 'height', ''
      $to_fit.parent().css 'min-height', ''

      height = Math.max $to_fit.outerHeight(), minheight

      $to_fit.css 'height', height
      $to_fit.parent().css 'min-height', height


    sizeToFit : (delay = 0, minheight = 0) ->
      if delay > 0
        _.delay =>
          @_sizeToFit minheight
        , delay
      else
        @_sizeToFit minheight

    events : 
      'mouseenter .point-peer' : 'logPointView'
      'click .points-list-region' : 'reasonsClicked'
      'click .participants' : 'reasonsClicked'      
      'click .reasons-footer-region' : 'reasonsClicked'            
      'mouseenter .points-list-region' : 'showViewResults'
      'mouseleave .points-list-region' : 'hideViewResults'
      'mouseenter .reasons-footer-region' : 'showViewResults'
      'mouseleave .reasons-footer-region' : 'hideViewResults'      
      'mouseenter .participants' : 'showViewResults'
      'mouseleave .participants' : 'hideViewResults'

    logPointView : (ev) ->
      if @state != Proposal.State.Summary
        pnt = $(ev.currentTarget).data('id')
        @trigger 'point:viewed', pnt

    reasonsClicked : (ev) ->
      if @state == Proposal.State.Summary && $(ev.target).closest('.reasons-header-region').length == 0
        @trigger 'show_results'
        ev.stopPropagation()

    showViewResults : (ev) ->
      return if @state != Proposal.State.Summary

      @hover_state = true
      @$el.find('.reasons-footer-region').css
        visibility: 'visible'

    hideViewResults : (ev) ->
      return if @state != Proposal.State.Summary || $(ev.target).closest('.reasons-view-results').length > 0
      @hover_state = false
      _.delay =>
        if !@hover_state
          @$el.find('.reasons-footer-region').css
            visibility: ''
      , 100

  class Proposal.ResultsFooterView extends App.Views.ItemView
    template : '#tpl_aggregate_footer_expanded'
    className : 'reasons-footer-sticky'

    serializeData : ->
      user_position = @model.getUserPosition()
      _.extend {}, @model.attributes,
        call : if user_position && user_position.get('published') then 'Update your position' else 'What do you think? Click to contribute your own position.'

  class Proposal.ResultsFooterCollapsedView extends App.Views.ItemView
    template : '#tpl_aggregate_footer_collapsed'

    serializeData : ->
      _.extend {}, @model.attributes

  class Proposal.ResultsFooterSeparatedView extends App.Views.ItemView
    template : '#tpl_aggregate_footer_separated'

    serializeData : ->
      _.extend {}, @model.attributes