@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->
  
  class Proposal.ProposalLayout extends App.Views.StatefulLayout
    template: '#tpl_proposal_layout'
    className : 'm-proposal'
    attributes : (include_data=true) ->
      prefix = if include_data then 'data-' else ''

      params = {}
      params["#{prefix}role"] = 'm-proposal'
      params["#{prefix}id"] = "#{@model.id}"
      params["#{prefix}activity"] = if @model.has_participants() then 'proposal-has-activity' else 'proposal-no-activity'
      params["#{prefix}status"] = if @model.get('active') then 'proposal-active' else 'proposal-inactive'
      params["#{prefix}visibility"] = if @model.get('published') then 'published' else 'unpublished'

      params

    regions: 
      descriptionRegion : '.m-proposal-description-region'
      stateToggleRegion : '.m-proposal-state-toggle-region'
      aggregateRegion : '.m-proposal-aggregate-region'
      reasonsRegion : '.m-proposal-reasons-region'

    initialize : (options = {}) ->
      super options

    onRender : ->
      super

    implodeParticipants : ->
      $participants = @$el.find('.l-message-speaker .l-group-container')

      $participants.hide()
      # $participants.find('.avatar').css 
      #   position: ''
      #   zIndex: ''
      #   '-ms-transform': ""
      #   '-moz-transform': ""
      #   '-webkit-transform': ""
      #   transform: ""

      $participants.find('.avatar[style]').removeAttr('style') # much more efficient

      # @$el.find('.m-histogram').css
      #   opacity: ''

      $participants.show()

    explodeParticipants : (transition = true) ->      
      modern = Modernizr.csstransforms && Modernizr.csstransitions

      $participants = @$el.find('.l-message-speaker.m-participants .l-group-container')

      $histogram = @$el.find('.m-histogram')

      if !modern || !transition
        $histogram.css 
          opacity: 1
          display: ''

        $participants.hide()
        @trigger 'explosion:complete'
      else
        $histogram.find('.m-bar-people').css
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

          to_offset = $to.offset()
          from_offset = $from.offset()

          offsetX = to_offset.left - from_offset.left
          offsetY = to_offset.top - from_offset.top

          offsetX -= (from_tile_size - to_tile_size)/2
          offsetY -= (from_tile_size - to_tile_size)/2

          positions[id] = [offsetX, offsetY]

        #_.delay =>

        for participant in $user_els
          $from = $(participant)
          id = $from.data('id')
          [offsetX, offsetY] = positions[id]
          
          rule = "rotate(180deg) scale(#{ratio},#{ratio}) translate(#{ 1/ratio * offsetX}px,#{ 1/ratio * offsetY}px)"
          $from.css 
            '-ms-transform':     rule,
            '-moz-transform':    rule,
            '-webkit-transform': rule,
            'transform':         rule

        _.delay =>
          $histogram.css { opacity: 1, display: '' }
          $histogram.find('.m-bar-people').css {visibility: ''}

          $participants.fadeOut()
          $participants_container.removeAttr 'style'

          @trigger 'explosion:complete'
        , speed + 10
        #, 1000 # give time for the description to slide down



  class Proposal.ParticipantsView extends App.Views.ItemView
    template: '#tpl_group_container'
    className : 'l-group-container'

    serializeData : ->
      participants = @model.getParticipants()

      _.extend {}, @model.attributes,
        tile_size : @getTileSize()
        participants : _.sortBy(participants, (user) -> !user.get('avatar_file_name')?  )


    getTileSize : ->
      PARTICIPANT_WIDTH = 150
      PARTICIPANT_HEIGHT = 150

      Math.min 50, 
        window.getTileSize(PARTICIPANT_WIDTH, PARTICIPANT_HEIGHT, @model.getParticipants().length)



  class Proposal.SocialMediaView extends App.Views.ItemView
    template : '#tpl_proposal_social_media'
    className : 'm-proposal-socialmedia'

