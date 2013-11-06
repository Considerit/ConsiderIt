@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->

  class Proposal.ReasonsLayout extends App.Views.StatefulLayout
    template: '#tpl_reasons_layout'
    className: 'l-message m-reasons'

    regions : 
      positionRegion : '.m-position-region'
      footerRegion : '.m-reasons-footer-region'      
      peerProsRegion : '.m-aggregated-propoints-region'
      peerConsRegion : '.m-aggregated-conpoints-region'
      participantsRegion : '.l-message-speaker'

    initialize : (options = {}) ->
      super options

    onRender : ->
      super

    pointExpanded : (region) ->
      region.$el.css 'zIndex', 12
      $transition_speed = 600
      @sizeToFit $transition_speed

    pointClosed : (region) ->
      region.$el.css 'zIndex', ''
      $transition_speed = 600
      @sizeToFit $transition_speed

    pointsBrowsing : (valence) ->
      $transition_speed = 600

      if valence == 'pro'
        @peerProsRegion.$el.addClass 'm-pointlist-browsing'
        @$el.addClass 'm-reasons-browsing m-reasons-browsing-pros'

      else
        @peerConsRegion.$el.addClass 'm-pointlist-browsing'
        @$el.addClass 'm-reasons-browsing m-reasons-browsing-cons'

      @sizeToFit $transition_speed * 1.5

    pointsBrowsingOff : (valence) ->
      $transition_speed = 600

      @peerConsRegion.$el.css 
        right: ''
        @positionRegion.$el.css 
          left: ''

      if valence == 'con'
        @peerProsRegion.$el.css 
          left: ''

        @peerConsRegion.$el.removeClass 'm-pointlist-browsing'
        @$el.removeClass 'm-reasons-browsing m-reasons-browsing-cons'

      else
        @peerProsRegion.$el.removeClass 'm-pointlist-browsing'
        @$el.removeClass 'm-reasons-browsing m-reasons-browsing-pros'

      @sizeToFit $transition_speed * 1.5

    sizeToFit : (delay = 0) ->
      _.delay =>
        $to_fit = @$el.find('.m-reasons-lists')

        $to_fit.css 'height', ''
        $to_fit.parent().css 'min-height', ''

        height = $to_fit.outerHeight()

        $to_fit.css 'height', height
        $to_fit.parent().css 'min-height', height

      , delay

    # ugly having this method here...
    includePoint : (model, $source, $dest, source) ->

      if false && $source.is('.m-point-unexpanded')
        $dest.css 'visibility', 'hidden'

        item_offset = $source.offset()
        ip_offset = $dest.offset()
        [offsetX, offsetY] = [ip_offset.left - item_offset.left, ip_offset.top - item_offset.top]

        styles = _.pick $dest.getStyles(), ['color', 'width', 'paddingRight', 'paddingLeft', 'paddingTop', 'paddingBottom']

        _.extend styles, 
          background: 'none'
          border: 'none'
          top: offsetY 
          left: offsetX
          position: 'absolute'

        $placeholder = $('<li class="m-point-peer">')
        $placeholder.css {height: $source.outerHeight(), visibility: 'hidden'}

        $source.find('.m-point-author-avatar, .m-point-include-wrap, .m-point-operations').fadeOut(50)

        $wrap = $source.find('.m-point-wrap')
        $wrap.css 
          position: 'absolute'
          width: $wrap.outerWidth()

        $placeholder.insertAfter $source

        $wrap.css(styles).delay(500).queue (next) =>
          $source.fadeOut -> 
            source.remove model
            $placeholder.remove()
            $dest.css 'visibility', ''
          next()
      else
        source.remove model

    events : 
      'mouseenter .m-point-peer' : 'logPointView'

    logPointView : (ev) ->
      pnt = $(ev.currentTarget).data('id')
      @trigger 'point:viewed', pnt


  class Proposal.ResultsFooterView extends App.Views.ItemView
    template : '#tpl_aggregate_footer_expanded'
    className : 'm-reasons-footer-sticky'

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