@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Proposal extends App.Entities.Model
    name: 'proposal'

    initialize : (options = {}) ->
      super options

      @long_id = @attributes.long_id

    url : () ->
      if @id
        Routes.proposal_path( @attributes.long_id ) 
      else
        Routes.proposals_path( )