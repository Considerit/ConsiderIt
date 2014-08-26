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
        if data.key?
          updated_user = data
        else
          updated_user = {}
          for updated in data
            if updated.key == '/current_user'
              updated_user = updated

        App.request "user:update_current_user", updated_user
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
          App.request "user:update_current_user", data
          layout.render()
          toastr.success 'Settings updated'

        else
          toastr.error "Error, #{data.reason}."

      layout

    getLayout : ->
      new User.AccountSettingsView
        model : @options.model

  class User.EmailNotificationsController extends App.Dash.RegionController
    data_uri : -> 
      Routes.followable_index_path {user_id : @options.model.id, u : @options.params['u'], t : @options.params['t']}

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
        params : @options.params
        model : @options.model
        followable_objects : @followable_objects