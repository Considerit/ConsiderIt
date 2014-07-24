@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Message extends App.Entities.Model
    name: 'message'

    initialize : (options = {}) ->
      super options
