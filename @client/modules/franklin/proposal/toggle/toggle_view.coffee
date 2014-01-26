
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
        call = 'View Your Opinion'
      else
        if updating
          call = 'Update Your Opinion'
        else
          if crafting 
            call = 'Craft Your Own Opinion' 
          else 
            call = 'Craft Your Own Opinion'
      
      results_call = 'View All Opinions'

      current_user = App.request 'user:current'
    
      _.extend {}, @model.attributes,
        results_call : results_call
        active : active
        updating : updating
        crafting : crafting
        call : call

    onRender : ->
      super
      position = @model.getUserPosition()
      @$el.attr 'data-updating', position && position.get 'published'