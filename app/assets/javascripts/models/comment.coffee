class ConsiderIt.Comment extends Backbone.Model
  defaults: 
    moderation_status : 1
  
  name: 'comment'

  url : () ->
    Routes.comments_path( )