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
    this