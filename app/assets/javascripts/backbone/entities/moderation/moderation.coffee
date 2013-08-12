@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Moderation extends App.Entities.Model
    name: 'moderation'

    initialize : (options = {}) ->
      super options

    setModeratedFields : (fields) ->
      @set 'moderated_fields', fields

    setModeratedObject : (obj) ->
      @moderated_object = obj

    failed : ->
      @get('status') == 0

    passed : ->
      @get('status') == 1

    quarantined : ->
      @get('status') == 2

    isCompleted : ->
      @get('status') == 1 || @get('status') == 0