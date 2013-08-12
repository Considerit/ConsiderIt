@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Comment extends App.Entities.Model
    name: 'comment'

    defaults: 
      moderation_status : 1

    initialize : (options = {}) ->
      super options
      @attributes.body = htmlFormat(@attributes.body)

    url : () ->
      if @id
        Routes.show_comment_path(@id)
      else
        Routes.comments_path( )