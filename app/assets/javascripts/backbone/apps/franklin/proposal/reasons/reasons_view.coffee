@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->

  class Proposal.ReasonsLayout extends App.Views.StatefulLayout
    template: '#tpl_reasons_layout'
    className: 'l-message m-reasons'

    regions : 
      positionRegion : '.m-position-region'
      footerRegion : '.m-reasons-footer-region'      
      peerProsRegion : '.m-aggregated-propoints-region'
      peerConsRegion : '.m-aggregated-conpoints-region'

    initialize : (options = {}) ->
      super options

    onRender : ->
      super

    pointExpanded : (region, inclusive) ->
      region.$el.css 'zIndex', 12
      @sizeToFit inclusive

    pointClosed : (region, inclusive) ->
      region.$el.css 'zIndex', ''
      @sizeToFit inclusive

    pointsBrowsing : (inclusive, valence) ->
      # $expanded_points_increment: 250px
      expansion_size = 250
      if valence == 'pro'
        @peerConsRegion.$el.css 
          right: parseInt(@peerConsRegion.$el.css('right')) - expansion_size

        @positionRegion.$el.css 
          left: expansion_size

        @peerProsRegion.$el.addClass 'm-pointlist-browsing'

      else
        @peerProsRegion.$el.css 
          left: parseInt(@peerProsRegion.$el.css('left')) - expansion_size
        @positionRegion.$el.css 
          left: -expansion_size
        # @peerConsRegion.$el.css 
        #   right: parseInt(@peerConsRegion.$el.css('right')) + expansion_size
        @peerConsRegion.$el.addClass 'm-pointlist-browsing'


      _.delay =>
        @sizeToFit inclusive
      , 500

    pointsBrowsingOff : (inclusive, valence) ->
      @peerConsRegion.$el.css 
        right: ''
        @positionRegion.$el.css 
          left: ''

      if valence == 'con'
        @peerProsRegion.$el.css 
          left: ''

        @peerConsRegion.$el.removeClass 'm-pointlist-browsing'
      else
        @peerProsRegion.$el.removeClass 'm-pointlist-browsing'


      _.delay =>
        @sizeToFit inclusive
      , 500

    sizeToFit : (inclusive) ->

      regions = _.compact [@peerProsRegion, @peerConsRegion]
      if regions.length > 0
        height = _.max (r.$el.height() for r in regions)
        height += @$el.children('.m-reasons-lists').height() if inclusive
      
      else
        height = 0
      @$el.css 'min-height', height

    # ugly having this method here...
    includePoint : (model, $source, $dest, source) ->

      # TODO: need to close point details if point is currently expanded
      # model.trigger('point:included') 

      if $source.is('.m-point-unexpanded')
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