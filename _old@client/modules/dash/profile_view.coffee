@ConsiderIt.module "Dash.User", (User, App, Backbone, Marionette, $, _) ->

  class User.UserProfileView extends App.Dash.View
    dash_name : 'profile'

    serializeData : ->

      [influenced_users, influenced_users_by_point] = @model.getInfluencedUsers()
      current_user = ConsiderIt.request 'user:current'
      
      params = _.extend {}, @model.attributes,
        influenced_users : influenced_users
        influenced_users_by_point : influenced_users_by_point
        comments : @model.getComments()
        opinions : @model.getOpinions()
        proposals : @model.getProposals()
        joined_at : @model.joinedAt()
        points : @model.getPoints() 
        is_self : @model.id == current_user.id
        tile_size : Math.min 50, window.getTileSize 400, 42, influenced_users.length

      params

    events : 
      'click .dashboard-profile-activity-summary' : 'activityToggled'

    activityToggled : (ev) ->
      already_selected = $(ev.currentTarget).is('.selected')
      @$el.find('.dashboard-profile-activity-block').hide()
      @$el.find('.dashboard-profile-activity-summary').removeClass('selected')

      if !already_selected
        action = $(ev.currentTarget).attr('action')    
        @$el.find("[action='#{action}-details']").slideDown()
        $(ev.currentTarget).addClass('selected')


  class User.EditProfileView extends App.Dash.View
    dash_name : 'edit_profile'

    serializeData : ->
      _.extend {}, @model.attributes, @model.permissions(),
        avatar : App.request('user:avatar', @model, 'original')

    events : 
      'ajax:complete .dashboard-edit-user' : 'userUpdated'

    userUpdated : (ev, response, options) ->
      data = $.parseJSON(response.responseText)
      @trigger 'user:update:requested', data

  class User.AccountSettingsView extends App.Dash.View
    dash_name : 'account_settings'

    serializeData : ->
      _.extend {}, @model.attributes, 
        third_party_authenticated : @model.authMethod() != 'email'
        auth_method : @model.authMethod()

    events : 
      'ajax:complete .dashboard-edit-user' : 'userUpdated'

    userUpdated : (ev, response, options) ->
      data = $.parseJSON(response.responseText)
      @trigger 'user:update:requested', data


  class User.EmailNotificationsView extends App.Dash.View
    dash_name : 'email_notifications'


    serializeData : ->
      tenant = App.request 'tenant'
      follows = @model.follows
      account_follower = _.has(follows, 'Account') && _.has(follows['Account'], tenant.id ) && follows['Account'][tenant.id].follow

      _.extend {}, @model.attributes,
        followable_objects : @options.followable_objects
        followable_types : [ 
          {label: 'Proposals', model: 'Proposal', explanation: 'When following a Proposal, you receive an email for each new pro/con point, as well as periodic email summaries of how the discussion is progressing.', attribute: 'name'}, 
          {label: 'Points', model: 'Point', explanation: 'When following a pro or con point, you receive an email whenever someone comments on it', attribute: 'nutshell'}]
        follows : follows
        account_follower : account_follower
        submit_text : if account_follower then 'Unsubscribe' else 'Subscribe'
        tenant_id : tenant.id
        u : @options.params['u']
        t : @options.params['t']
        
    events : 
      'ajax:complete .dashboard-notifications-unfollow_all' : 'unfollowed_all'
      'ajax:complete .dashboard-notifications-unfollow' : 'unfollow'

    unfollowed_all : (ev, response, status) ->
      location.reload()

    unfollow : (ev, response, status) ->
      data = $.parseJSON(response.responseText)
      return if !data.success || data.success == 'false'
      follow = data.follow
      delete @options.followable_objects[follow.followable_type][follow.followable_id]
      @trigger 'unfollow', data.follow
      @render



