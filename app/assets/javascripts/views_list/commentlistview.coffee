class ConsiderIt.CommentListView extends Backbone.CollectionView

  itemView : ConsiderIt.CommentView
  @childClass : 'comment'
  @newcomment_template : _.template( $('#tpl_newcomment').html() )
  listSelector : '.commentlist'

  initialize : (options) -> 
    super
    @commentable_type = options.commentable_type
    @commentable_id = options.commentable_id
  
  render : () -> 
    super
    @$el.append(ConsiderIt.CommentListView.newcomment_template({user : ConsiderIt.current_user }))

  # Returns an instance of the view class
  getItemView: (comment)->
    new @itemView
      model: comment
      collection: @collection
      attributes :
        class : "comment"

  #handlers
  events :
    'click .comment_submit' : 'create_new_comment'

  comment_attributes : ($form) -> 
    body : $form.find('#comment_body').val()
    user_id : ConsiderIt.current_user.id
    commentable_type : @commentable_type
    commentable_id : @commentable_id

  create_new_comment : (ev) ->
    
    attrs = @comment_attributes( @$el.find('.new_comment') )

    @collection.create attrs,
      success : (data) ->