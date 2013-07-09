class ConsiderIt.CommentView extends Backbone.View

  tagName : 'li'
  @template : _.template( $("#tpl_comment").html() )

  initialize : (options) -> 
    @commentable = options.commentable

  render : () -> 
    @$el.html(
      ConsiderIt.CommentView.template($.extend({}, @model.attributes, {
        user : ConsiderIt.users[@model.get('user_id')]
      }))
    )

    #TODO: if user logs in as admin, need to do this
    if ConsiderIt.current_user.id == @model.get('user_id') #|| ConsiderIt.roles.is_admin
      @$el.find('.m-comment-body').editable {
          resource: 'comment'
          pk: @model.id
          url: Routes.update_comment_path @model.id
          type: 'textarea'
          name: 'body'
          success : (response, new_value) => @model.set('body', new_value)

        }

    this