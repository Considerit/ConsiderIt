@ConsiderIt.module "Views", (Views, App, Backbone, Marionette, $, _) ->
  
  class Views.Layout extends Marionette.Layout
    constructor : (options = {}) ->
      @options = options
      super options

  class Views.StatefulLayout extends Marionette.Layout
    initialize : (options = {}) ->
      @state = options.state

    onRender : ->
      @setDataState @state

    setDataState : (state) ->
      @$el.attr 'data-state', state
      @$el.data 'state', state
      @state = state      
