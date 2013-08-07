@ConsiderIt.module "Dash", (Dash, App, Backbone, Marionette, $, _) ->

  class Dash.Layout extends App.Views.Layout
    template: "#tpl_dashboard_container"

    regions :
      sidebarRegion : '.m-dashboard-sidebar-region'
      mainRegion : '.m-dashboard-main-region'

  class Dash.Sidebar extends App.Views.ItemView
    template: '#tpl_dashboard_sidebar'

    serializeData : ->
      _.extend {}, @model.attributes, @model.permissions(),
        avatar : @model.get_avatar_url 'original'
        tenant : ConsiderIt.current_tenant
        is_self : @model.id == ConsiderIt.request('user:current').id

    updateActiveLink : (dash_name) ->
      @$el.find('.m-dashboard_link').removeClass('current').filter("[data-target='#{dash_name}']").addClass('current')


  # Abstract view to be extended by main region specific views
  class Dash.View extends App.Views.Layout
    checkboxes : {}
    getTemplate: -> 
      "#tpl_dashboard_#{@dash_name}"

    checkBox : (model, attribute, selector, condition) ->
      if model == 'user'
        model = @model
      else if model == 'account'
        model = ConsiderIt.current_tenant

      if condition || (!condition? && model.get(attribute))
        input = document.getElementById(selector).checked = true

    onShow : ->
      @$el.addClass("m-dashboard-#{@dash_name}")
      
      _.each @checkboxes, (checkbox) =>
        @checkBox(checkbox...)


  class Dash.UnauthorizedView extends Dash.View
    dash_name : 'unauthorized'



    

