@ConsiderIt.module "Shared", (Shared, App, Backbone, Marionette, $, _) ->
  class Shared.AuthView extends Backbone.View

    events : 
      'click [action="login"]' : 'loginDialogRequested'
      'click [action="create_account"]' : 'createDialogRequested'

    loginDialogRequested : (ev) ->
      App.vent.trigger 'signin:requested'
      ev.stopPropagation()

    createDialogRequested : (ev) ->
      App.vent.trigger 'registration:requested'
      ev.stopPropagation()

  class Shared.ProfileView extends Backbone.View
    template : _.template $('#tpl_user_tooltip').html()

    events : 
      'mouseenter [action="user_profile_page"]' : 'tooltipShow'
      'mouseleave [action="user_profile_page"]' : 'tooltipHide'
      'click [action="user_profile_page"]' : 'viewProfile'


    viewProfile : (ev) -> 
      App.navigate(Routes.profile_path($(ev.currentTarget).data('id')), {trigger: true})
      ev.stopPropagation()
      
    tooltipShow : (ev) ->
      $target = $(ev.currentTarget)
      if !$target.closest('.l-tooltip-user').length > 0
        user = App.request 'user', $target.data('id')

        if $target.closest('[role="proposal"]').length > 0
          long_id = $target.closest('[role="proposal"]').data('id')
          proposal = App.request 'proposal:get', long_id

          proposal = null if !proposal.user_participated(user.id) 

        tooltip = @template 
          user : user.attributes
          proposal : proposal
          joined_at : user.joinedAt()
          metrics : [ 
            ['influence', 'metric_influence', 'major'], 
            ['points', 'metric_points', 'minor'], 
            ['votes', 'metric_opinions', 'minor'], 
            ['comments', 'metric_comments', 'minor']  ]


        @$el.append tooltip
        $tooltip = @$el.children '.l-tooltip-user'

        $target.tooltipster
          interactive: true
          content: $tooltip
          offsetY: -5
          delay: 700
        $target.tooltipster 'show'

    tooltipHide : (ev) ->
      @$el.children('.l-tooltip-user, .l-tooltip-user-title').remove()


