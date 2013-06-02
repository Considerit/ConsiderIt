
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
        proposal : @proposal.attributes,
        is_you : @user == ConsiderIt.current_user
      )
    )

    #TODO: if user logs in as admin, need to do this
    #TODO: need to allow people who haven't logged in to edit their own points
    # if (ConsiderIt.current_user && ConsiderIt.current_user.id == @model.get('user_id')) || ConsiderIt.roles.is_admin
    #   @$el.find('.m-point-nutshell').editable {
    #       resource: 'point'
    #       pk: @model.id
    #       url: Routes.proposal_point_path @proposal.long_id, @model.id
    #       type: 'textarea'
    #       name: 'nutshell'
    #     }

    this


  do_after_data_loaded : (callback, callback_params) ->
    if @model.data_loaded
      callback(this, callback_params)
    else      
      @listenToOnce @model, 'point:data_loaded', => 
        callback(this, callback_params)
      @model.load_data()


  show_point_details : (me) ->
    me.pointdetailsview = new ConsiderIt.PointDetailsView( {proposal : me.proposal, model: me.model, el: me.$el} )
    me.pointdetailsview.render()

  show_point_details_handler : () -> @do_after_data_loaded(@show_point_details)