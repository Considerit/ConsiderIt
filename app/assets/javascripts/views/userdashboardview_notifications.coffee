#TODO: this shouldn't be loaded with all the other classes, most won't use it
class ConsiderIt.UserDashboardViewNotifications extends Backbone.View
  
  initialize : (options) -> 
    @template = _.template( $("#tpl_dashboard_email_notifications").html() )
    @followable_objects = options.data.followable_objects
    @user = if ConsiderIt.pinned_user && !ConsiderIt.current_user.is_logged_in() then ConsiderIt.pinned_user else ConsiderIt.current_user 
    super

  render : () -> 
    params = 
      user: @user.attributes
      followable_objects: @followable_objects
      follows: @user.follows

    @$el.html(
      @template( params )
    )

    this


  events : 
    'ajax:complete .m-dashboard-notifications-unfollow_all' : 'unfollowed_all'
    'ajax:complete .m-dashboard-notifications-unfollow' : 'unfollow'


  unfollowed_all : (ev, response, status) ->
    @user.unfollow_all()
    @render()


  unfollow : (ev, response, status) ->
    data = $.parseJSON(response.responseText)
    follow = data.follow.follow
    @user.set_following(follow)
    @render()