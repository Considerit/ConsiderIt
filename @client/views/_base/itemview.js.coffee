@ConsiderIt.module "Views", (Views, App, Backbone, Marionette, $, _) ->
  
  class Views.ItemView extends Marionette.ItemView

    constructor : (options = {}) ->
      @options = options
      super options