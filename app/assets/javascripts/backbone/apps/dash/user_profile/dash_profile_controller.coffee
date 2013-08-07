@ConsiderIt.module "Dash", (Dash, App, Backbone, Marionette, $, _) ->

  class Dash.ProfileController extends Dash.RegionController
    data_uri : -> 
      if @options.model.is_meta_data_loaded()
        null
      else 
        Routes.profile_path @options.model.id

    process_data_from_server : (data) ->
      @options.model.set_meta_data data
      data


  class Dash.UserProfileController extends Dash.ProfileController

    setupLayout : ->
      @getLayout()

    getLayout : ->
      new Dash.UserProfileView
        model : @options.model

  class Dash.EditProfileController extends Dash.ProfileController

    setupLayout : ->
      layout = @getLayout()
      @listenTo layout, 'user:update:requested', (data) =>
        App.request "user:current:update", data.user
        layout.render()
      layout


    getLayout : ->
      new Dash.EditProfileView
        model : @options.model

  class Dash.AccountSettingsController extends Dash.ProfileController

    setupLayout : ->
      @getLayout()

    getLayout : ->
      new Dash.AccountSettingsView
        model : @options.model

  class Dash.EmailNotificationsController extends Dash.RegionController
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
      new Dash.EmailNotificationsView
        model : @options.model
        followable_objects : @followable_objects