@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->

  class Proposal.ReasonsLayout extends App.Views.StatefulLayout
    template: '#tpl_reasons_layout'
    className: 'reasons'

    regions : 
      opinionRegion : '.opinion-region'
      footerRegion : '.reasons-footer-region'      
      communityProsRegion : '.community-pros-region'
      communityConsRegion : '.community-cons-region'
      participantsRegion : '.participants'

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

    _sizeToFit : (minheight) ->
      $to_fit = @$el.find('.four_columns_of_points')

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
      'mouseenter .community_point' : 'logPointView'
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
      if @state == Proposal.State.Summary && $(ev.target).closest('.decision-board-heading-region').length == 0
        @trigger 'show_results'
        ev.stopPropagation()

    showViewResults : (ev) ->
      return if @state != Proposal.State.Summary

      @hover_state = true
      @$el.find('.reasons-footer-region').css
        visibility: 'visible'

    hideViewResults : (ev) ->
      return if @state != Proposal.State.Summary || $(ev.target).closest('.view_results_prompt_from_summary').length > 0
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
      user_opinion = @model.getUserOpinion()
      _.extend {}, @model.attributes,
        call : if user_opinion && user_opinion.get('published') then 'Update your opinion' else 'What do you think? Click to contribute your own opinion.'

  class Proposal.ResultsFooterCollapsedView extends App.Views.ItemView
    template : '#tpl_aggregate_footer_collapsed'

    serializeData : ->
      _.extend {}, @model.attributes

  class Proposal.ResultsFooterSeparatedView extends App.Views.ItemView
    template : '#tpl_aggregate_footer_separated'

    serializeData : ->
      _.extend {}, @model.attributes