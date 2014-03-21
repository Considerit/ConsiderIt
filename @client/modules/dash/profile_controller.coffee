@ConsiderIt.module "Dash.User", (User, App, Backbone, Marionette, $, _) ->

  class User.ProfileController extends App.Dash.RegionController
    data_uri : -> 
      if @options.model.isFetched()
        null
      else 
        Routes.profile_path @options.model.id

    process_data_from_server : (data) ->
      @options.model.parse data
      data


  class User.UserProfileController extends User.ProfileController

    setupLayout : ->
      @getLayout()

    getLayout : ->
      new User.UserProfileView
        model : @options.model

  class User.EditProfileController extends User.ProfileController

    setupLayout : ->
      layout = @getLayout()
      @listenTo layout, 'user:update:requested', (data) =>
        App.request "user:update_current_user", data.user
        layout.render()
      layout


    getLayout : ->
      new User.EditProfileView
        model : @options.model

  class User.AccountSettingsController extends User.ProfileController

    setupLayout : ->
      layout = @getLayout()
      @listenTo layout, 'user:update:requested', (data) =>
        if data.result == 'successful'
          App.request "user:update_current_user", data.user
          layout.render()
          App.execute 'notify:success', 'Settings updated'

        else
          App.execute 'notify:failure', "Error, #{data.reason}."

      layout

    getLayout : ->
      new User.AccountSettingsView
        model : @options.model

  class User.EmailNotificationsController extends App.Dash.RegionController
    data_uri : -> 
      Routes.followable_index_path {user_id : @options.model.id}

    process_data_from_server : (data) ->
      @followable_objects = data.followable_objects
      data

    setupLayout : ->
      layout = @getLayout()
      @listenTo layout, 'unfollow', (follow) ->
        @options.model.setFollowing follow
        layout.render()
      @listenTo layout, 'unfollow:all', ->
        @options.model.unfollowAll()
        layout.render()
      layout

    getLayout : ->
      new User.EmailNotificationsView
        model : @options.model
        followable_objects : @followable_objects