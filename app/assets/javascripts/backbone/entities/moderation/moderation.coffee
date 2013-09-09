@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Moderation extends App.Entities.Model
    name: 'moderation'

    defaults: 
      moderation_status : 1
      updated_since_last_evaluation : false
      notification_sent : false

    initialize : (options = {}) ->
      super options

    setModeratedFields : (fields) ->
      @set 'moderated_fields', fields

    setModeratedObject : (obj) ->
      @moderated_object = obj

    getRootObject : -> 
      @moderated_object

    failed : ->
      @get('status') == 0

    passed : ->
      @get('status') == 1

    quarantined : ->
      @get('status') == 2

    isCompleted : ->
      @get('status') == 1 || @get('status') == 0

    hasBeenUpdatedSinceLastEvaluation : ->
      @get 'updated_since_last_evaluation'