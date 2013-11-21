
@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->

  class Proposal.StateToggleView extends App.Views.StatefulLayout
    template : '#tpl_proposal_state_toggle'
    className : 'm-proposal-state-toggle'


    serializeData : ->
      position = @model.getUserPosition()
      updating = position && position.get 'published'
      active = @model.get 'active'
      crafting = @state == Proposal.ReasonsState.separated
      
      if !active && updating
        call = 'View your opinion'
      else
        if updating
          call = 'Update your opinion'
        else
          call = if crafting then 'Adding your own opinion' else 'Add your own opinion'

      current_user = App.request 'user:current'
      _.extend {}, @model.attributes,
        active : active
        updating : updating
        crafting : crafting
        call : call

    onRender : ->
      super
      position = @model.getUserPosition()
      @$el.attr 'data-updating', position && position.get 'published'