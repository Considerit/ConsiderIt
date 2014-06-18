@ConsiderIt.module "Header", (Header, App, Backbone, Marionette, $, _) ->
  
  class Header.Layout extends App.Views.Layout
    template: "#tpl_header"

    regions:
      userNavRegion: "#user_nav"
      navRegion : '.l-navigate'
      logoRegion : '#header_logo_region'

  class Header.NavView extends App.Views.ItemView
    template: '#tpl_header_nav'
    className : 'l-navigate-wrap'

    # serializeData : ->
    #   _.extend {},
    #     crumbs : @options.crumbs

    events : 
      'click .l-navigate-back' : 'goBack'

    goBack : (ev) ->
      ev.stopPropagation()
      App.request 'nav:back:history'

  class Header.LogoView extends App.Views.ItemView
    template: '#tpl_header_logo'
    className : 'header-logo'