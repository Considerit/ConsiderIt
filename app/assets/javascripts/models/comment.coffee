class ConsiderIt.Comment extends Backbone.Model
  defaults: 
    moderation_status : 1
  
  name: 'comment'

  initialize : ->
    super
    @attributes.body = htmlFormat(@attributes.body)

  url : () ->
    Routes.comments_path( )