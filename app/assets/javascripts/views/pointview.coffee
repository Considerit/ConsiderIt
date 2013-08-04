
class ConsiderIt.PointView extends Backbone.View

  tagName : 'li'
  data_loaded : false
  user : null
  @template : _.template( $("#tpl_point").html() )

  initialize : (options) -> 
    @proposal = options.proposal
    @model.on('change', @render, this)
    @reset_listeners()

  reset_listeners : () ->
    user = if this.model.get('user_id') then ConsiderIt.users[this.model.get('user_id')] else ConsiderIt.request('user:current')
    if !@user? || user.id != @user.id
      @user.off('change', @render, this) if @user?
      @user = user
      @user.on('change', @render, this)

  render : () -> 
    return if @$el.is('.m-point-expanded')
    @reset_listeners()
    @$el.html(
      ConsiderIt.PointView.template $.extend({}, @model.attributes,
        adjusted_nutshell : this.model.adjusted_nutshell()
        user : @user.attributes
        proposal : @proposal.attributes,
        is_you : @user == ConsiderIt.request('user:current')
      )
    )
    
    @stickit()
    this

  bindings : 
    '.m-point-read-more' : 
      observe : 'comment_count'
      onGet : -> if @model.get('comment_count') == 1 then "1 comment" else "#{@model.get('comment_count')} comments"

  do_after_data_loaded : (callback, callback_params) ->
    if @model.data_loaded
      callback.apply(this, [callback_params])
    else      
      @listenToOnce @model, 'point:data_loaded', => 
        callback.apply(this, [callback_params])
      @model.load_data()


  show_point_details : ->
    @pointdetailsview = new ConsiderIt.PointDetailsView( {proposal : @proposal, model: @model, el: @$el} )
    @pointdetailsview.render()

  show_point_details_handler : () -> @do_after_data_loaded(@show_point_details)