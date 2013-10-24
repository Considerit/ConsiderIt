@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->

  class Proposal.ReasonsLayout extends App.Views.StatefulLayout
    template: '#tpl_reasons_layout'
    className: 'l-message m-reasons'

    regions : 
      positionRegion : '.m-position-region'
      reasonsHeaderRegion : '.m-reasons-header-region'
      footerRegion : '.m-reasons-footer-region'      
      peerProsRegion : '.m-aggregated-propoints-region'
      peerConsRegion : '.m-aggregated-conpoints-region'

    initialize : (options = {}) ->
      super options

    onRender : ->
      super

    sizeToFit : ->
      height = _.max [@peerProsRegion.$el.height(), @peerConsRegion.$el.height()]
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




  class Proposal.ResultsHeaderView extends App.Views.ItemView
    template: '#tpl_reasons_results_header'
    className : 'm-reasons-header'

    serializeData : ->
      @model.attributes

    updateHeader : (segment) ->
      if segment == 'all'
        aggregate_heading = @$el.find '.m-results-pro-con-list-who-all'
        aggregate_heading.siblings('.m-results-pro-con-list-who-others').hide()
        aggregate_heading.show()
      else 
        others = @$el.find '.m-results-pro-con-list-who-others'
        others.siblings('.m-results-pro-con-list-who-all').hide()
        group_name = App.Entities.Position.stance_name segment
        others
          .html("The most compelling Pros and Cons for <span class='group_name'>#{group_name}</span>")
          .show()

  class Proposal.ResultsHeaderViewCollapsed extends App.Views.ItemView
    template: '#tpl_reasons_results_header_collapsed'
    className : 'm-reasons-header'

    serializeData : ->
      @model.attributes

  class Proposal.ResultsHeaderViewSeparated extends App.Views.ItemView
    template: '#tpl_reasons_results_header_separated'
    className : 'm-reasons-header'

    serializeData : ->
      @model.attributes

  class Proposal.ResultsFooterView extends App.Views.ItemView
    template : '#tpl_aggregate_footer_expanded'
    className : 'm-reasons-footer-sticky'

    serializeData : ->
      user_position = @model.getUserPosition()
      _.extend {}, @model.attributes,
        call : if user_position && user_position.get('published') then 'Update your position' else 'Add your thoughts'

  class Proposal.ResultsFooterCollapsedView extends App.Views.ItemView
    template : '#tpl_aggregate_footer_collapsed'

    serializeData : ->
      _.extend {}, @model.attributes

  class Proposal.ResultsFooterSeparatedView extends App.Views.ItemView
    template : '#tpl_aggregate_footer_separated'

    serializeData : ->
      _.extend {}, @model.attributes