@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->
  
  class Proposal.ProposalLayout extends App.Views.StatefulLayout
    template: '#tpl_proposal_layout'
    className : 'proposal_layout'
    attributes : (include_data=true) ->
      params = {}
      params["role"] = 'proposal'
      params["#{if include_data then 'data-' else ''}id"] = "#{@model.id}"
      params["activity"] = if @model.has_participants() then 'proposal-has-activity' else 'proposal-no-activity'
      params["status"] = if @model.get('active') then 'proposal-active' else 'proposal-inactive'
      params["visibility"] = if @model.get('published') then 'published' else 'unpublished'

      params

    regions: 
      descriptionRegion : '.proposal_description_region'
      stateToggleRegion : '.toggle_proposal_state_region'
      histogramRegion : '.proposal_histogram_region'
      reasonsRegion : '.proposal_reasons_region'


    initialize : (options = {}) -> super options

    onRender : -> super

    events : 
      'click [action="user_opinion"]' : 'viewUserOpinion'

    viewUserOpinion : (ev) -> 
      App.navigate(Routes.user_opinion_proposal_path(@model.id, $(ev.currentTarget).data('id')), {trigger: true})
      ev.stopPropagation()

    implodeParticipants : ->
      $participants = @$el.find('.participating_users_view')

      $participants.hide()
      $participants.find('.avatar[style]').removeAttr('style') # much more efficient
      $participants.show()

    explodeParticipants : (transition = true) ->      
      modern = Modernizr.csstransforms && Modernizr.csstransitions

      $participants = @$el.find('.participating_users_view')

      $histogram = @$el.find('.histogram_layout')

      if !modern || !transition
        $histogram.css 
          opacity: 1
          display: ''

        $participants.hide()
        @trigger 'explosion:complete'
      else
        $histogram.find('.histogram_bar_users').css
          visibility: 'hidden'

        speed = 1200
        from_tile_size = $participants.find('.avatar:first').width()
        to_tile_size = $histogram.find(".avatar:first").width()
        ratio = to_tile_size / from_tile_size

        $participants_container = $participants.parent()
        $participants_offset = $participants_container.offset()
        $participants_container.css
          top: $participants_offset.top - $participants_container.parent().offset().top
          bottom: 'auto'

        # compute all offsets first, before applying changes, for perf reasons
        positions = {}
        $user_els = $participants.find('.avatar')
        for participant in $user_els
          $from = $(participant)          
          id = $from.data('id')

          $to = $histogram.find("#avatar-#{id}")
          if $to.length == 0 # can happen if user gets destroyed but positions weren't updated
            $from.remove()
            continue

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
          if !(id of positions)
            continue

          [offsetX, offsetY] = positions[id]

          
          rule = "rotate(180deg) scale(#{ratio},#{ratio}) translate(#{ 1/ratio * offsetX}px,#{ 1/ratio * offsetY}px)"
          $from.css 
            '-ms-transform':     rule,
            '-moz-transform':    rule,
            '-webkit-transform': rule,
            'transform':         rule

        _.delay =>
          $histogram.css { opacity: 1, display: '' }
          $histogram.find('.histogram_bar_users').css {visibility: ''}

          $participants.hide()
          $participants_container.removeAttr 'style'

          @trigger 'explosion:complete'
        , speed + 10



  class Proposal.ParticipatingUsersView extends App.Views.ItemView
    template: '#tpl_participating_users'
    className : 'participating_users_view'

    serializeData : ->
      participants = @model.getParticipants()

      _.extend {}, @model.attributes,
        tile_size : @getTileSize()
        participants : _.sortBy(participants, (user) -> !user.get('avatar_file_name')?  )


    getTileSize : ->
      PARTICIPANT_WIDTH = 150
      PARTICIPANT_HEIGHT = 150

      Math.min 50, 
        window.getTileSize(PARTICIPANT_WIDTH, PARTICIPANT_HEIGHT, @model.num_participants())



