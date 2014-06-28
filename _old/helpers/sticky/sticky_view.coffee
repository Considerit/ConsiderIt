@ConsiderIt.module "Helpers.Sticky", (Sticky, App, Backbone, Marionette, $, _) ->
  class Sticky.StickyLayout extends App.Views.Layout
    template: '#tpl_sticky_footer'
    className : 'l-sticky-footer-wrap'
    regions:
      contentRegion: ".l-sticky-content-region"