@ConsiderIt.module "Shared", (Shared, App, Backbone, Marionette, $, _) ->

  class Shared.ProfileView extends Backbone.View
    template : _.template $('#tpl_user_tooltip').html()

    events : 
      'mouseenter [data-target="user_profile_page"]' : 'tooltipShow'
      'mouseleave [data-target="user_profile_page"]' : 'tooltipHide'
      'click [data-target="user_profile_page"]' : 'viewProfile'
      "click a[href^='/']" : 'processLink'


    viewProfile : (ev) -> 
      App.navigate(Routes.profile_path($(ev.currentTarget).data('id')), {trigger: true})

    tooltipShow : (ev) ->
      $target = $(ev.currentTarget)
      if !$target.closest('.l-tooltip-user').length > 0
        user = App.request 'user', $target.data('id')

        if $target.closest('[data-role="m-proposal"]').length > 0
          proposal_id = $target.closest('[data-role="m-proposal"]').data('id')
          proposal = App.request 'proposal:get:id', proposal_id

          proposal = null if !proposal.user_participated(user.id) 

        tooltip = @template 
          user : user.attributes
          proposal : proposal
          joined_at : user.joinedAt()
          metrics : [ 
            ['influence', 'metric_influence', 'major'], 
            ['points', 'metric_points', 'minor'], 
            ['votes', 'metric_positions', 'minor'], 
            ['comments', 'metric_comments', 'minor']  ]


        @$el.append tooltip
        $tooltip = @$el.children '.l-tooltip-user'

        $target.tooltipster
          interactive: true
          content: $tooltip
          offsetY: -5
          delay: 400
        $target.tooltipster 'show'

    tooltipHide : (ev) ->
      @$el.children('.l-tooltip-user, .l-tooltip-user-title').remove()


    processLink : (event) ->
      href = $(event.currentTarget).attr('href')
      target = $(event.currentTarget).attr('target')

      if target == '_blank' || href == '/newrelic'  || $(event.currentTarget).data('remote') # || href[1..9] == 'dashboard'
        return true

      # Allow shift+click for new tabs, etc.
      if !event.altKey && !event.ctrlKey && !event.metaKey && !event.shiftKey
        event.preventDefault()
        # Instruct Backbone to trigger routing events
        App.navigate(href, { trigger : true })
        return false