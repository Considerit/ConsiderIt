class ConsiderIt.AppView extends Backbone.View

  # el: '#l-content'
  # breadcrumbs_template : _.template($('#tpl_breadcrumbs').html())
  # homepage_heading : _.template($('#tpl_homepage_heading').html())

  # initialize : (options) -> 

  #   @listenTo ConsiderIt.vent, 'user:signin', =>
 
  #   @listenTo ConsiderIt.vent, 'user:signout', => 
  #     ConsiderIt.router.navigate(Routes.root_path(), {trigger: true})

  #   ConsiderIt.router.bind 'all', (route, router) => @route_changed(route, router)

  #   @history = [ ['homepage', '/'] ]
  #   @last_page = '/'

  # render : () ->

  #   @$el.find('#t-bg-content-top').append(@homepage_heading())

  #   ConsiderIt.vent.on 'tenant:updated', ->
  #     @$el.find('.t-intro-wrap').replaceWith @homepage_heading()

  #   @proposals_manager = new ConsiderIt.ProposalsManagerView({el : '#t-bg-content-top'}) 

  #   @proposals_manager.render()

  #   # kick off events for the current path
  #   # ConsiderIt.router.navigate @last_page, {trigger: true}
  #   this

  # events : 
  #   'click .l-navigate-back' : 'go_back'
  #   # 'mouseenter [data-target="user_profile_page"]' : 'tooltip_show'
  #   # 'mouseleave [data-target="user_profile_page"]' : 'tooltip_hide'
  #   # 'click [data-target="user_profile_page"]' : 'view_user_profile'

  # view_user_profile : (ev) -> ConsiderIt.router.navigate(Routes.profile_path($(ev.currentTarget).data('id')), {trigger: true})

  # go_back : ->
  #   @history.pop()
  #   if @history.length < 2
  #     ConsiderIt.router.navigate(Routes.root_path(), {trigger: true})
  #   else
  #     route = @history.pop()[1]
  #     ConsiderIt.router.navigate(route, {trigger: true})

  # go_back_crumb : ->
  #   href = if @breadcrumbs.length > 1 then @breadcrumbs[@breadcrumbs.length - 2][1] else '/'
  #   ConsiderIt.router.navigate(href, {trigger: true, replace: false})

  route_changed : (route, router) ->
    return if route == 'route'
    ## wait for endpoint to finish rendering ...

    loc = Backbone.history.fragment.split('?')[0].split('/')
    short = loc[loc.length - 1]
    $('.tooltipster-base').hide()
    
    if short 
      new_crumbs = []
      for [loc,full] in @history
        break if loc == short
        new_crumbs.push [loc,full]
      @history = new_crumbs
      @history.push [short, "/#{Backbone.history.fragment.split('?')[0]}"]
    else
      @history = [['homepage','/']]
    
    $back = $('.l-navigate')

    if @history.length == 1 && $back.is(':visible')
      $("[data-domain='homepage']:hidden").show()

      $back.hide()
    else if @history.length > 1
      @breadcrumbs = [['homepage', '/']]
      path = ''
      for loc in @history[@history.length-1][1].split('/')
        continue if loc.length == 0
        path = "#{path}/#{loc}"
        @breadcrumbs.push [loc.split('?')[0], path] if ConsiderIt.router.valid_endpoint(path)

      # ######################
      # #### HACK: if static position or point details, need to insert "results" into breadcrumbs if loaded from results page
      # if _.contains(['route:PointDetails', 'route:StaticPosition'], route) && ($('.m-position:visible').length == 0)
      #   @breadcrumbs.splice(@breadcrumbs.length - 1, 0, ['results', "#{@breadcrumbs[@breadcrumbs.length - 2][1]}/results"])
      # ######

      $("[data-domain='homepage']:visible").hide()

      $(document).scrollTop(0) if @last_page == '/' && !_.contains(['route:PointDetails', 'route:StaticPosition'], route)
        

      $back.find('.l-navigate-breadcrumbs').html @breadcrumbs_template({crumbs: @breadcrumbs})
      $back.show()

    @last_page = _.last(@history)[1]


  # user_tooltip_template : _.template( $("#tpl_user_tooltip").html() )

  # tooltip_show : (ev) ->
  #   $target = $(ev.currentTarget)
  #   if !$target.closest('.l-tooltip-user').length > 0
  #     user = ConsiderIt.users[$target.data('id')]

  #     if $target.closest('[data-role="m-proposal"]').length > 0
  #       proposal = ConsiderIt.all_proposals.get($target.closest('[data-role="m-proposal"]').data('id'))
  #       proposal = null if !proposal.user_participated(user.id) 

  #     tooltip = @user_tooltip_template {user : user, proposal : proposal}
      
  #     $('body').append(tooltip)
  #     $tooltip = $('body > .l-tooltip-user')

  #     $target.tooltipster
  #       interactive: true
  #       content: $tooltip
  #       offsetY: -5
  #       delay: 400
  #     $target.tooltipster 'show'


  # tooltip_hide : (ev) ->
  #   target = $(ev.currentTarget)
  #   #if !$target.closest('.l-tooltip-user').length > 0
  #   $('body > .l-tooltip-user, body > .l-tooltip-user-title').remove()

