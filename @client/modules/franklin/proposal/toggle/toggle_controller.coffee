@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->

  class Proposal.StateToggleController extends App.Controllers.StatefulController
    transitions_enabled : true

    initialize : (options = {}) ->
      super options

      @model = options.model

      @layout = @getLayout()

      @setupLayout @layout

      @region.show @layout

    stateWasChanged : ->
      #_.delay =>
      @layout.render()
      #, @transition_speed() + 10


    setupLayout : (layout) ->
      @listenTo layout, 'show', =>
        null

    getLayout : ->
      new Proposal.StateToggleView
        model : @model
        state : @state

