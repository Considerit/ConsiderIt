@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->

  class Proposal.ReasonsLayout extends App.Views.StatefulLayout
    template: '#tpl_reasons_layout'
    className: 'reasons_layout'

    regions : 
      opinionRegion : '.opinion_region'
      footerRegion : '.reasons_footer_region'      
      communityProsRegion : '.community_pros_region'
      communityConsRegion : '.community_cons_region'
      participantsRegion : '.participating_users_region'

    initialize : (options = {}) ->
      super options

    onRender : ->
      super

    pointWasOpened : (region) ->
      region.$el.css 'zIndex', 12
      $transition_speed = if Modernizr.csstransitions then 1000 else 0
      @sizeToFit $transition_speed

    pointWasClosed : (region) ->
      region.$el.css 'zIndex', ''
      $transition_speed = if Modernizr.csstransitions then 1000 else 0
      @sizeToFit $transition_speed

    pointsWereExpanded : (valence) ->

      if valence == 'pro'
        @communityProsRegion.$el.addClass 'points_are_expanded'
        @$el.addClass 'some_points_are_expanded pro_points_are_expanded'

      else
        @communityConsRegion.$el.addClass 'points_are_expanded'
        @$el.addClass 'some_points_are_expanded con_points_are_expanded'

      @sizeToFit 10

    pointsWereUnexpanded : (valence) ->
      @communityConsRegion.$el.css 
        right: ''
        @opinionRegion.$el.css 
          left: ''

      if valence == 'con'
        @communityProsRegion.$el.css 
          left: ''

        @communityConsRegion.$el.removeClass 'points_are_expanded'
        @$el.removeClass 'some_points_are_expanded con_points_are_expanded'

      else
        @communityProsRegion.$el.removeClass 'points_are_expanded'
        @$el.removeClass 'some_points_are_expanded pro_points_are_expanded'

      @sizeToFit 10


    sizeToFit : (delay = 0, minheight = 0) ->
      if delay > 0
        _.delay =>
          @_sizeToFit minheight
        , delay
      else
        @_sizeToFit minheight

    _sizeToFit : (minheight) ->
      $to_fit = @$el.find('.four_columns_of_points')

      $to_fit.css 'height', ''
      $to_fit.parent().css 'min-height', ''

      height = Math.max $to_fit.outerHeight(), minheight

      $to_fit.css 'height', height
      $to_fit.parent().css 'min-height', height

      
    events : 
      'click .points_list_region' : 'reasonsClicked'
      'click .reasons_footer_region' : 'reasonsClicked'            
      'mouseenter .points_list_region' : 'showViewResults'
      'mouseleave .points_by_community' : 'hideViewResults'
      'mouseenter .reasons_footer_region' : 'showViewResults'
      'mouseleave .reasons_footer_region' : 'hideViewResults'      
      'mouseenter .community_point' : 'logPointView'

    reasonsClicked : (ev) ->
      if @state == Proposal.State.Summary && $(ev.target).closest('.decision_board_heading_region').length == 0
        @trigger 'show_results'
        ev.stopPropagation()

    showViewResults : (ev) ->
      return if @state != Proposal.State.Summary

      @hover_state = true
      @$el.find('.reasons_footer_region').css
        visibility: 'visible'

    hideViewResults : (ev) ->
      return if @state != Proposal.State.Summary || $(ev.target).closest('.results_prompt_from_summary_view').length > 0 || ($(ev.target).is('.reasons_footer_region') && !$(ev.target).is('.points_by_community'))

      @hover_state = false
      _.delay =>
        if !@hover_state
          @$el.find('.reasons_footer_region').css
            visibility: ''
      , 100

    logPointView : (ev) ->
      if @state != Proposal.State.Summary
        pnt = $(ev.currentTarget).data('id')
        @trigger 'point:viewed', pnt


  class Proposal.ViewResultsView extends App.Views.ItemView
    template : '#tpl_view_results'
    className : 'results_prompt_from_summary_view'
    serializeData : ->
      _.extend {}, @model.attributes
