@ConsiderIt.module "Dash", (Dash, App, Backbone, Marionette, $, _) ->

  class Dash.UserProfileView extends Dash.View
    dash_name : 'profile'

    serializeData : ->
      influenced_users = _.keys(@model.meta.influenced_users) || []

      _.extend {}, @model.attributes, @model.meta, 
        is_self : @model.id == ConsiderIt.request('user:current').id
        tile_size : Math.min 50, ConsiderIt.utils.get_tile_size 400, 42, influenced_users.length

    events : 
      'click .m-dashboard-profile-activity-summary' : 'activityToggled'

    activityToggled : (ev) ->
      already_selected = $(ev.currentTarget).is('.selected')
      @$el.find('.m-dashboard-profile-activity-block').hide()
      @$el.find('.m-dashboard-profile-activity-summary').removeClass('selected')

      if !already_selected
        target = $(ev.currentTarget).data('target')    
        @$el.find("[data-target='#{target}-details']").slideDown()
        $(ev.currentTarget).addClass('selected')


  class Dash.EditProfileView extends Dash.View
    dash_name : 'edit_profile'

    serializeData : ->
      _.extend {}, @model.attributes, @model.permissions(),
        avatar : @model.get_avatar_url 'original'

    events : 
      'ajax:complete .m-dashboard-edit-user' : 'userUpdated'

    userUpdated : (ev, response, options) ->
      data = $.parseJSON(response.responseText)
      @trigger 'user:update:requested', data

  class Dash.AccountSettingsView extends Dash.View
    dash_name : 'account_settings'

    serializeData : ->
      @model.attributes

  class Dash.EmailNotificationsView extends Dash.View
    dash_name : 'email_notifications'

    serializeData : ->
      _.extend {}, @model.attributes,
        followable_objects: @options.followable_objects
        follows : @model.follows

    events : 
      'ajax:complete .m-dashboard-notifications-unfollow_all' : 'unfollowed_all'
      'ajax:complete .m-dashboard-notifications-unfollow' : 'unfollow'

    unfollowed_all : (ev, response, status) ->
      @trigger 'unfollow:all'

    unfollow : (ev, response, status) ->
      data = $.parseJSON(response.responseText)
      follow = data.follow.follow
      @trigger 'unfollow', data.follow.follow



