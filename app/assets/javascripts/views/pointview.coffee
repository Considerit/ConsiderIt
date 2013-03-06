
class ConsiderIt.PointView extends Backbone.View

  tagName : 'li'
  data_loaded : false
  user : null
  @template : _.template( $("#tpl_point").html() )
  @expanded_point_template : _.template( $("#tpl_point_details").html() )

  initialize : (options) -> 
    @proposal = options.proposal
    @model.on('change', @render, this)
    @reset_listeners()

  reset_listeners : () ->
    user = if this.model.get('user_id') then ConsiderIt.users[this.model.get('user_id')] else ConsiderIt.current_user
    if !@user? || user.id != @user.id
      @user.off('change', @render, this) if @user?
      @user = user
      @user.on('change', @render, this)

  render : () -> 
    @reset_listeners()
    @$el.html(
      ConsiderIt.PointView.template $.extend({}, @model.attributes,
        adjusted_nutshell : this.model.adjusted_nutshell()
        user : @user.attributes
        proposal : @proposal.model.attributes,
        is_you : @user == ConsiderIt.current_user
      )
    )

    #TODO: if user logs in as admin, need to do this
    if ConsiderIt.current_user.id == @model.user_id || ConsiderIt.roles.is_admin
      @$el.find('.m-point-nutshell').editable {
          resource: 'point'
          pk: @model.id
          url: Routes.proposal_point_path @proposal.model.attributes.long_id, @model.id
          type: 'textarea'
          name: 'nutshell'
        }

    this

  load_data : (callback) ->
    $.get Routes.proposal_point_path(@proposal.model.get('long_id'), @model.id), (data) =>
      comments = (co.comment for co in data.comments)
      ConsiderIt.comments[@model.id] = new ConsiderIt.CommentList()
      ConsiderIt.comments[@model.id].reset(comments)

      console.log data
      @model.update_assessable_data(data)

      @data_loaded = true
      callback(this)

  show_point_details : (me) ->
    overlay = $('<div class="l-overlay" id="point_details_overlay">')
    me.proposal.view.$el.prepend(overlay)
    
    me.proposal.view.trigger 'point_details:staged'

    me.pointdetailsview = new ConsiderIt.PointDetailsView( {proposal : me.proposal, model: me.model, el: overlay} )
    me.pointdetailsview.render()


  show_point_details_handler : () ->

    if @data_loaded
      @show_point_details(this)
    else
      @load_data(@show_point_details)
