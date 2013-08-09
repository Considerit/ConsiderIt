@ConsiderIt.module "Dash", (Dash, App, Backbone, Marionette, $, _) ->

  class Dash.Controller extends App.Controllers.Base

    initialize : (options = {}) ->
      @layout = @getLayout()

      App.vent.on 'user:updated', =>
        @sidebar.render() if @sidebar

      App.vent.on 'user:signin', =>
        @layout.render()

      App.vent.on 'user:signout', =>
        @layout.close()
        @close()

    renderSidebar : (model, dash_name) ->
      if !@sidebar || @sidebar.model.id != model.id 
        @sidebar = @getSidebar(model)
        @layout.sidebarRegion.show @sidebar

      @sidebar.updateActiveLink dash_name

    getLayout : ->
      new Dash.Layout  

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
        $.get path, request_params, (data, status, xhr) =>
          if load_admin_template
            $('head').append(data.admin_template)

          if 'unauthorized' of data && data['unauthorized']
            App.vent.trigger 'authorization:page_not_allowed'
          else
            data = @process_data_from_server(data) if @process_data_from_server
            @trigger 'preload_complete', data
      else
        @trigger 'preload_complete', {}

    setupLayout : -> 
      throw 'Need to implement layout setup'



  class Dash.UnauthorizedController extends Dash.RegionController
    setupLayout : ->
      new Dash.UnauthorizedView

