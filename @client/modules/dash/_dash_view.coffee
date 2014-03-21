@ConsiderIt.module "Dash", (Dash, App, Backbone, Marionette, $, _) ->

  class Dash.DashLayout extends App.Views.Layout
    template: "#tpl_dashboard_container"
    className: 'dashboard-wrapper'
    regions :
      sidebarRegion : '.dashboard-sidebar-region'
      mainRegion : '.dashboard-main-region'

  class Dash.Sidebar extends App.Views.ItemView
    template: '#tpl_dashboard_sidebar'
    className : 'sidebar'

    serializeData : ->
      current_user = App.request 'user:current' 
      params = _.extend {}, @model.attributes, @model.permissions(),
        avatar : App.request('user:avatar', @model, 'original')
        tenant : App.request("tenant")
        is_self : @model.id == current_user.id

      params

    updateActiveLink : (dash_name) ->
      @$el.find('.sidebar_link').removeClass('selected').filter("[action='#{dash_name}']").addClass('selected')


  # Abstract view to be extended by main region specific views
  class Dash.View extends App.Views.Layout
    checkboxes : {}
    getTemplate: -> 
      "#tpl_dashboard_#{@dash_name}"

    checkBox : (model, attribute, selector, condition) ->
      if model == 'user'
        model = @model
      else if model == 'account'
        model = App.request("tenant")

      if condition || (!condition? && model.get(attribute))
        input = document.getElementById(selector).checked = true

    radioBox : (model, attribute, selector) ->
      if model == 'user'
        model = @model
      else if model == 'account'
        model = App.request("tenant")

      input = document.getElementById("#{selector}_#{model.get(attribute)}").checked = true


    onShow : ->
      @$el.addClass("dashboard-#{@dash_name}")
      
      _.each @checkboxes, (checkbox) =>
        @checkBox(checkbox...)

      _.each @radioboxes, (radiobox) =>
        @radioBox(radiobox...)


  class Dash.UnauthorizedView extends Dash.View
    dash_name : 'unauthorized'


  class Dash.EmailDialogView extends App.Views.ItemView
    template : '#tpl_dash_email_dialog_view'
    
    dialog : 
      title : 'Send Email'

    onShow : ->
      @$el.find('textarea').autosize()


    serializeData : ->
      _.extend {}, @model.attributes

    events : 
      'ajax:complete form' : 'emailReturned'

    emailReturned : (ev, response, options) ->

      data = $.parseJSON(response.responseText)
      if data.result == 'success'
        App.execute 'notify:success', 'Email sent!'
      else
        App.execute 'notify:failure', 'Failed to send email'

      @trigger 'email:returned', data




