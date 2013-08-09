@ConsiderIt.module "Dash.User", (User, App, Backbone, Marionette, $, _) ->

  class User.ProfileController extends App.Dash.RegionController
    data_uri : -> 
      if @options.model.is_meta_data_loaded()
        null
      else 
        Routes.profile_path @options.model.id

    process_data_from_server : (data) ->
      @options.model.set_meta_data data
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
        App.request "user:current:update", data.user
        layout.render()
      layout


    getLayout : ->
      new User.EditProfileView
        model : @options.model

  class User.AccountSettingsController extends User.ProfileController

    setupLayout : ->
      @getLayout()

    getLayout : ->
      new User.AccountSettingsView
        model : @options.model

  class User.EmailNotificationsController extends App.Dash.RegionController
    data_uri : -> 
      Routes.followable_index_path({user_id : @options.model.id})

    process_data_from_server : (data) ->
      @followable_objects = data.followable_objects
      data

    setupLayout : ->
      layout = @getLayout()
      @listenTo layout, 'unfollow', (follow) ->
        @options.model.set_following(follow)
        layout.render()
      @listenTo layout, 'unfollow:all', ->
        @options.model.unfollow_all()
        layout.render()
      layout

    getLayout : ->
      new User.EmailNotificationsView
        model : @options.model
        followable_objects : @followable_objects