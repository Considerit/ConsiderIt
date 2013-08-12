@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Point extends App.Entities.Model
    name: 'point'

    initialize : (options = {}) ->
      super options

      @attributes.nutshell = htmlFormat(@attributes.nutshell)
      @attributes.text = htmlFormat(@attributes.text)


    url : () ->

      if @id
        Routes.proposal_point_path( @get('long_id'), @id) 
      else
        Routes.proposal_points_path( @get('long_id') ) 
