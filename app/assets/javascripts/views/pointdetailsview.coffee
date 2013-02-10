class ConsiderIt.PointDetailsView extends Backbone.View

  @template : _.template $("#tpl_point_details").html()

  initialize : (options) -> 
    @proposal = options.proposal
    @listenTo @proposal.view, 'point_details:staged', -> @remove()

  render : () -> 
    @$el.html ConsiderIt.PointDetailsView.template($.extend({}, @model.attributes, {
        adjusted_nutshell : this.model.adjusted_nutshell(),
        user : ConsiderIt.users[this.model.get('user_id')],
        proposal : @proposal.model.attributes
      }))
    
    @commentsview = new ConsiderIt.CommentListView({
      collection: ConsiderIt.comments[@model.id], 
      el: @$el.find('.discuss')
      commentable_id: @model.id,
      commentable_type: 'Point'})
    @commentsview.renderAllItems()
    this

    $('html, body').animate {scrollTop: @$el.offset().top - 50}, 1000


  events : 
    'click .close' : 'close_details'

  close_details : (ev) ->
    @commentsview.clear()
    @commentsview.remove()
    @$el.html ''
    @remove()