@ConsiderIt.module "Views", (Views, App, Backbone, Marionette, $, _) ->
  
  class Views.CollectionView extends Marionette.CollectionView
    itemViewEventPrefix: "childview"

    constructor : (options = {}) ->
      @options = options
      super options