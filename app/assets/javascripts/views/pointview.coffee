
class ConsiderIt.PointView extends Backbone.View

  tagName : 'li'
  @template : _.template( $("#tpl_point_in_list").html() )

  @expanded_point_template : _.template( $("#tpl_point_details").html() )

  initialize : (options) -> 
    #options.parent.on("include:#{this.model.attributes.id}", this.include, this);
    @proposal = options.proposal
    @data_loaded = false

  render : () -> 
    user = if this.model.get('user_id') then ConsiderIt.users[this.model.get('user_id')] else ConsiderIt.current_user
    @$el.html(
      ConsiderIt.PointView.template $.extend({}, @model.attributes,
        adjusted_nutshell : this.model.adjusted_nutshell()
        user : user.attributes
        proposal : @proposal.model.attributes,
        is_you : user == ConsiderIt.current_user
      )
    )
    this

  load_data : (callback) ->
    $.get Routes.proposal_point_path(@proposal.model.get('long_id'), @model.id), (data) =>
      comments = (co.comment for co in $.parseJSON(data.comments))
      ConsiderIt.comments[@model.id] = new ConsiderIt.CommentList()
      ConsiderIt.comments[@model.id].reset(comments)

      @data_loaded = true
      callback(this)

  show_point_details : (me) ->
    overlay = $('<div class="point_details_overlay">')
    me.proposal.view.$el.find('.user_opinion').prepend(overlay)
    
    me.pointdetailsview = new ConsiderIt.PointDetailsView( {proposal : me.proposal, model: me.model, el: overlay} )
    me.pointdetailsview.render()

  show_point_details_handler : () ->
    if @data_loaded
      @show_point_details()
    else
      @load_data(@show_point_details)
