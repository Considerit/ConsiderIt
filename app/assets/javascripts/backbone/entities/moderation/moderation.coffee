@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Moderation extends App.Entities.Model
    name: 'moderation'

    initialize : (options = {}) ->
      super options

    setModeratedFields : (fields) ->
      @set 'moderated_fields', fields
