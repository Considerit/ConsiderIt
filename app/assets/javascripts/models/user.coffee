class ConsiderIt.User extends Backbone.Model
  @available_roles = ['superadmin', 'admin', 'analyst', 'moderator', 'manager', 'evaluator', 'developer']

  defaults: { }
  name: 'user'

  initialize : ->
    
  url : ->
    Routes.user_path( @attributes.id )

  auth_method : ->
    if @attributes.google_uid?
      return 'google' 
    else if @attributes.facebook_uid?
      return 'facebook'
    else if @attributions.twitter_uid?
      return 'twitter'
    else
      return 'email'

  roles : ->
    return [] if !@attributes.roles_mask? || @attributes.roles_mask == 0

    all_roles = ConsiderIt.User.available_roles

    user_roles = []
    me = this
    for element, idx in all_roles
      if (me.attributes.roles_mask & Math.pow(2, idx)) > 0
        user_roles.push element

    user_roles

  is_logged_in : ->
    'id' of @attributes

  has_role : (role) ->
    _.indexOf(@roles(), role) >= 0

  role_list: ->
    @roles().join(', ')

  is_common_user : ->
    roles = @roles()
    !roles? || roles.length == 0

  set_follows : (follows) ->
    follows = ( f.follow for f in follows )
    @follows = {}
    for f in follows
      @follows[f.followable_type] = {} if !(f.followable_type of @follows)
      @follows[f.followable_type][f.followable_id] = f
    
  is_following : (followable_type, followable_id) ->
    return @follows[followable_type][followable_id] if followable_type of @follows && followable_id of @follows[followable_type] && @follows[followable_type][followable_id].follow == true
    false

  set_following : (follow) ->
    @follows[follow.followable_type] = {} if !follow.followable_type of @follows
    @follows[follow.followable_type][follow.followable_id] = follow