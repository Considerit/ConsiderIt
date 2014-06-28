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
    template : '#tpl_user_tooltip'

    events : 
      'mouseenter [data-tooltip="user_profile"]' : 'tooltipShow'
      'mouseleave [data-tooltip="user_profile"]' : 'tooltipHide'
      'click [action="user_profile_page"]' : 'viewProfile'


    viewProfile : (ev) -> 
      App.navigate(Routes.profile_path($(ev.currentTarget).data('id')), {trigger: true})
      ev.stopPropagation()
      
    tooltipShow : (ev) ->
      $target = $(ev.currentTarget)
      if !$target.closest('.l_tooltip-user').length > 0
        user = App.request 'user', $target.data('id')

        if $target.closest('[data-role="proposal"]').length > 0
          long_id = $target.closest('[data-role="proposal"]').data('id')
          proposal = App.request 'proposal:get', long_id

          proposal = null if !proposal.user_participated(user.id) 

        if !Shared.ProfileView.compiled_template
          Shared.ProfileView.compiled_template = _.template $(@template).html()

        tooltip = Shared.ProfileView.compiled_template
          user : user.attributes
          proposal : proposal
          metrics : [ 
            ['influence', 'metric_influence', 'major'], 
            ['points', 'metric_points', 'minor'], 
            ['votes', 'metric_opinions', 'minor'], 
            ['comments', 'metric_comments', 'minor']  ]


        #@$el.append tooltip
        #$tooltip = @$el.children '.l_tooltip-user'

        $target.tooltipster
          interactive: false
          content: $(tooltip)
          offsetY: -12
          delay: 7000
          interactiveTolerance: 0
          onlyOne: true
          speed: 0
          arrow: false
          position: 'top-left'

        $target.tooltipster 'show'

    tooltipHide : (ev) ->
      @$el.children('.l_tooltip-user').remove()


