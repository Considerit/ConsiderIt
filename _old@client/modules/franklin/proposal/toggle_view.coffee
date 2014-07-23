
@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->

  class Proposal.ToggleProposalStateView extends App.Views.StatefulLayout
    template : '#tpl_toggle_proposal_state'
    className : 'toggle_proposal_state_view'


    serializeData : ->
      opinion = @model.getUserOpinion()
      updating = opinion && opinion.get 'published'
      active = @model.get 'active'
      crafting = @state == Proposal.State.Crafting
      
      if active 
        call = if updating then 'Update Your Opinion' else 'Craft Your Own Opinion'
      else
        call = if updating then 'View Your Opinion' else 'Craft your Own Opinion'
      
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
      opinion = @model.getUserOpinion()
      @$el.attr 'data-updating', opinion && opinion.get 'published'