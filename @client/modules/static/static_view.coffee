@ConsiderIt.module "Static", (Static, App, Backbone, Marionette, $, _) ->

  class Static.StaticLayout extends App.Views.Layout
    className : 'static-page'
    template : '#tpl_static_layout'

    regions : 
      mainRegion : '#static-main-region'
      sidebarRegion : '#static-sidebar-region'

    serializeData : ->
      title : @options.title


  class Static.StaticSidebar extends App.Views.ItemView
    className : 'sidebar'
    template : '#tpl_static_sidebar'

    serializeData : ->
      tenant : App.request('tenant')

    onShow : ->
      @$el.find("[action='#{@options.page}']").addClass('current')


  class Static.StaticView extends App.Views.ItemView
    className : 'static-content'
    getTemplate : ->
      "#tpl_static_#{@options.page}"

