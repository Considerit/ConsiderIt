class ConsiderIt.Comment extends Backbone.Model
  defaults: 
    moderation_status : 1
  
  name: 'comment'

  initialize : ->
    super
    @attributes.body = htmlFormat(@attributes.body)

  url : () ->
    if @id
      Routes.show_comment_path(@id)
    else
      Routes.comments_path( )