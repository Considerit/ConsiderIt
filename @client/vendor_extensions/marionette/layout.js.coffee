@ConsiderIt.module "Views", (Views, App, Backbone, Marionette, $, _) ->
  
  class Views.Layout extends Marionette.Layout
    constructor : (options = {}) ->
      @options = options
      super options

  class Views.StatefulLayout extends Views.Layout
    initialize : (options = {}) ->
      @state = options.state

    onRender : ->
      @setDataState @state

    setDataState : (state) ->
      @$el.attr 'state', state
      @$el.data 'state', state

      if @state != state
        @$el.attr 'coming-from-state', @state
        @$el.data 'state-from', @state

        @state = state      

    enterTransition : ->
      @$el.addClass 'transitioning'

    exitTransition : ->
      @$el.removeClass 'transitioning'