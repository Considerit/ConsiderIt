@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->
  class Proposal.AggregateProposalDescription extends Proposal.ProposalDescriptionView

  class Proposal.AggregateLayout extends App.Views.Layout
    template : '#tpl_aggregate_layout'
    className : 'm-proposal'
    attributes : ->
      "data-role": 'm-proposal'
      "data-id": "#{@model.id}"


    regions : 
      proposalRegion : '.m-proposal-description-region'
      histogramRegion : '.m-histogram-region'
      reasonsRegion : '.m-reasons-region'

    serializeData : ->
      participants = @model.getParticipants()
      user_position = @model.getUserPosition()
      _.extend {}, @model.attributes,
        tile_size : @getTileSize()
        participants : _.sortBy(participants, (user) -> !user.get('avatar_file_name')?  )
        call : if user_position && user_position.get('published') then 'Update your position' else 'What do you think?'


    getTileSize : ->
      PARTICIPANT_WIDTH = 150
      PARTICIPANT_HEIGHT = 110

      Math.min 50, 
        window.getTileSize(PARTICIPANT_WIDTH, PARTICIPANT_HEIGHT, @model.getParticipants().length)

    onRender : ->
      @$el.attr('data-state', 4)

    moveToResults : ->
      @histogramRegion.currentView.$el.moveToTop 100

    implodeParticipants : ->
      @trigger 'results:implode_participants'
      $participants = @$el.find('.l-message-speaker .l-group-container')
      $participants.find('.avatar').css {position: '', zIndex: '', '-ms-transform': "", '-moz-transform': "", '-webkit-transform': "", transform: ""}

      @$el.find('.m-bar-percentage').fadeOut()
      @$el.find('.m-histogram').fadeOut =>
        @$el.find('.m-histogram').css('opacity', '')
        $participants.fadeIn()

    explodeParticipants : (transition = true) ->
      @trigger 'results:explode_participants'

      modern = Modernizr.csstransforms && Modernizr.csstransitions

      $participants = @$el.find('.l-message-speaker .l-group-container')

      $histogram = @$el.find('.m-histogram')

      if !modern || !transition
        @$el.find('.m-histogram').css 'opacity', 1
        $participants.fadeOut()
      else
        speed = 750
        from_tile_size = $participants.find('.avatar:first').width()
        to_tile_size = $histogram.find(".avatar:first").width()
        ratio = to_tile_size / from_tile_size

        # compute all offsets first, before applying changes, for perf reasons
        positions = {}
        $user_els = $participants.find('.avatar')
        for participant in $user_els
          $from = $(participant)
          id = $from.data('id')
          $to = $histogram.find("#avatar-#{id}")

          to_offset = $to.offset()
          from_offset = $from.offset()

          offsetX = to_offset.left - from_offset.left
          offsetY = to_offset.top - from_offset.top

          offsetX -= (from_tile_size - to_tile_size)/2
          offsetY -= (from_tile_size - to_tile_size)/2

          positions[id] = [offsetX, offsetY]

        for participant in $user_els
          $from = $(participant)
          id = $from.data('id')
          [offsetX, offsetY] = positions[id]
          
          $from.css 
            #'-o-transform': "scale(#{ratio},#{ratio}) translate(#{ 1/ratio * offsetX}px,#{ 1/ratio * offsetY}px)",
            '-ms-transform': "scale(#{ratio},#{ratio}) translate(#{ 1/ratio * offsetX}px,#{ 1/ratio * offsetY}px)",
            '-moz-transform': "scale(#{ratio},#{ratio}) translate(#{ 1/ratio * offsetX}px,#{ 1/ratio * offsetY}px)",
            '-webkit-transform': "scale(#{ratio},#{ratio}) translate(#{ 1/ratio * offsetX}px,#{ 1/ratio * offsetY}px)",
            'transform': "scale(#{ratio},#{ratio}) translate(#{ 1/ratio * offsetX}px,#{ 1/ratio * offsetY}px)"

        _.delay => 
          $histogram.css { opacity: 1, display: '' }
          #window.delay 25, -> 
          $participants.fadeOut()
          #@$el.find('.m-bar-percentage').fadeIn()
        , speed + 150


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

    closeBarClick : (ev) -> @deselectBar() if $(ev.target).closest('.m-results-responders').length == 0

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


  class Proposal.AggregateReasons extends App.Views.Layout
    template : '#tpl_aggregate_reasons'
    className : 'm-aggregate-reasons'
    regions : 
      prosRegion : '.m-aggregated-propoints-region'
      consRegion : '.m-aggregated-conpoints-region'

    events : 
      'click .point_filter:not(.selected)' : 'sortAll'

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
          .html("The most compelling considerations for us <span class='group_name'>#{group_name}</span>")
          .show()
