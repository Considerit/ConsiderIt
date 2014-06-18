@ConsiderIt.module "Dash", (Dash, App, Backbone, Marionette, $, _) ->

  class Dash.DashController extends App.Controllers.Base

    initialize : (options = {}) ->
      @layout = @getLayout()

      App.vent.on 'user:updated', =>
        @sidebar.render() if @sidebar

      App.vent.on 'user:signin', =>        
        @layout.mainRegion.currentView.render() if @layout.mainRegion && @layout.mainRegion.currentView
        @layout.sidebarRegion.currentView.render() if @layout.sidebarRegion && @layout.sidebarRegion.currentView

      App.vent.on 'user:signout', =>
        @layout.close()
        App.navigate Routes.root_path(), {trigger : true}
        @close()

    renderSidebar : (model, dash_name) ->
      if !@sidebar || @sidebar.model.id != model.id 
        @sidebar = @getSidebar model
        @layout.sidebarRegion.show @sidebar

      @sidebar.updateActiveLink dash_name

    getLayout : ->
      new Dash.DashLayout  

    getSidebar : (model) ->
      new Dash.Sidebar
        model: model


  # Abstract controller to be extended by main region specific controllers
  class Dash.RegionController extends App.Controllers.Base
    admin_template_needed : false
    data_uri : null
    request_params : {}
    process_data_from_server : null

    initialize : (options = {}) ->
      if !@redirected
        @on 'preload_complete', (data) => 
          view = @setupLayout()
          @region.show view
          App.vent.trigger 'dashboard:region:rendered', @options.model, view.dash_name

        @preload()


    preload : ->
      load_admin_template = @admin_template_needed && !App.request("admin_templates_loaded?")
      
      path = _.result @, 'data_uri'
      if !path && load_admin_template
        path = Routes.admin_template_path() 

      if path
        request_params = _.extend @request_params, {admin_template_needed : load_admin_template}
        xhr = $.get path, request_params, (data, status, xhr) =>
          if load_admin_template
            $('head').append(data.admin_template)

          if 'unauthorized' of data && data['unauthorized']
            App.vent.trigger 'authorization:page_not_allowed'
          else
            data = @process_data_from_server(data) if @process_data_from_server
            @trigger 'preload_complete', data
        
        App.execute 'show:loading',
          loading:
            entities : xhr
            xhr: true

      else
        @trigger 'preload_complete', {}

    setupLayout : -> 
      throw 'Need to implement layout setup'



  class Dash.UnauthorizedController extends Dash.RegionController
    setupLayout : ->
      new Dash.UnauthorizedView

  class Dash.EmailDialogController extends App.Controllers.Base
    email_defaults : 
      sender : null
      recipient : null
      preamble : ''      
      body : ''
      subject : ''

    email : ->
      @email_defaults

    initialize : ->
      view = @getEmailView()
      @listenTo view, 'show', =>
        @setupLayout view

      dialog_overlay = @getOverlay view

      @listenTo view, 'email:returned', (response) ->
        dialog_overlay.close()
        @close()

      @listenTo dialog_overlay, 'dialog:canceled', =>
        @close()

    setupLayout : ->

    getMessage : ->
      new App.Entities.Message _.extend(@email_defaults, @email())

    getOverlay : (view) ->
      App.request 'dialog:new', view, 
        class: 'overlay_email_dialog'

    getEmailView : ->
      new Dash.EmailDialogView
        model : @getMessage()


