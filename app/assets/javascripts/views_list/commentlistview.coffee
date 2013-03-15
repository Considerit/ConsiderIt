class ConsiderIt.CommentListView extends Backbone.CollectionView

  itemView : ConsiderIt.CommentView
  @childClass : 'm-comment'
  @newcomment_template : _.template( $('#tpl_newcomment').html() )
  listSelector : '.m-point-comments'

  initialize : (options) -> 
    super
    @commentable_type = options.commentable_type
    @commentable_id = options.commentable_id
  
  render : () -> 
    super
    @$el.append(ConsiderIt.CommentListView.newcomment_template({user : ConsiderIt.current_user }))

    @$el.find('[placeholder]').simplePlaceholder()

    for el in @$el.find('.m-new-comment .is_counted')
      $(el).NobleCount $(el).siblings('.count'), {
        block_negative: true,
        max_chars : parseInt($(el).siblings('.count').text()) }        



  # Returns an instance of the view class
  getItemView: (comment)->
    new @itemView
      model: comment
      collection: @collection
      attributes :
        class : "m-comment"

  #handlers
  events :
    'click .m-new-comment-submit' : 'create_new_comment'

  comment_attributes : -> 
    body : @$el.find('.m-new-comment-body-field').val()
    user_id : ConsiderIt.current_user.id
    commentable_type : @commentable_type
    commentable_id : @commentable_id

  create_new_comment : (ev) ->
    
    attrs = @comment_attributes( )

    @collection.create attrs,
      success : (data) ->