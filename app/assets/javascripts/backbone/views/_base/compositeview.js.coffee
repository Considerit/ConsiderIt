@ConsiderIt.module "Views", (Views, App, Backbone, Marionette, $, _) ->
  
  class Views.CompositeView extends Marionette.CompositeView
    itemViewEventPrefix: "childview"

    constructor : (options = {}) ->
      @options = options
      super options