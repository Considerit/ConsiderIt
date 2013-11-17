@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->

  class Proposal.StateToggleController extends App.Controllers.StatefulController
    transition_speed : -> 
      $transition_speed = 1000
      $transition_speed

    state_map : ->
      map = {}
      map[Proposal.State.collapsed] = Proposal.ReasonsState.collapsed
      map[Proposal.State.expanded.crafting] = Proposal.ReasonsState.separated
      map[Proposal.State.expanded.results] = Proposal.ReasonsState.together
      map

    initialize : (options = {}) ->
      super options

      @model = options.model

      @layout = @getLayout()

      @setupLayout @layout

      @region.show @layout

    processStateChange : ->
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

