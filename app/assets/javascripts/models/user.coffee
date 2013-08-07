class ConsiderIt.User extends Backbone.Model
  @available_roles = ['superadmin', 'admin', 'analyst', 'moderator', 'manager', 'evaluator', 'developer']

  defaults: { 
    bio : ''
  }
  
  name: 'user'

  initialize : ->
    @follows = {}
    
  url : ->
    Routes.user_path( @attributes.id )

  auth_method : ->
    attrs = @attributes
    if 'google_uid' of attrs && attrs.google_uid? && attrs.google_uid.length > 0
      return 'google' 
    else if 'facebook_uid' of attrs && attrs.facebook_uid? && attrs.facebook_uid.length > 0
      return 'facebook'
    else if 'twitter_uid' of attrs && attrs.twitter_uid? && attrs.twitter_uid.length > 0
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

  is_persisted : ->
    'id' of @attributes

  is_logged_in : ->
    #TODO: this method is technically incorrect...having a user id does not mean
    # that the user is logged in, only in the limited auth scenario where this
    # method is being used to detect whether a user has been created or not...
    # need to update this so there is an authoritative indicator from the server
    'id' of @attributes

  paperwork_completed : ->
    @get('registration_complete')

  is_admin : -> @has_role('admin')
  is_moderator : -> @is_admin || @has_role('moderator')
  is_analyst : -> @is_admin || @has_role('analyst')
  is_evaluator : -> @is_admin || @has_role('evaluator')
  is_manager : -> @is_admin || @has_role('manager')

  permissions : ->
    is_admin: @is_admin()
    is_analyst: @is_analyst()
    is_evaluator: @is_evaluator()
    is_manager: @is_manager()
    is_moderator: @is_moderator()


  has_role : (role) ->
    _.indexOf(@roles(), role) >= 0

  update_role : (roles_mask) ->
    @set 'roles_mask', roles_mask

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
    if @is_logged_in() && followable_type of @follows && followable_id of @follows[followable_type] && @follows[followable_type][followable_id].follow == true
      return @follows[followable_type][followable_id] 
    else
      false
      
  set_following : (follow) ->
    @follows[follow.followable_type] = {} if !_.has(@follows, follow.followable_type)
    @follows[follow.followable_type][follow.followable_id] = follow

  # unfollow : (followable_type, followable_id) ->
  #   follow = @follows[followable_type][followable_id] if followable_type of @follows && if followable_id of @follows[followable_type]
  #   follow.explicit = true
  #   follow.follow = false

  unfollow_all : ->
    for fgroup in _.values(@follows)
      for follow in _.values(fgroup)
        follow.explicit = true
        follow.follow = false

  get_avatar_url : (size, fname) ->
    if fname?
      "#{ConsiderIt.public_root}/system/avatars/#{@id}/#{size}/#{fname}"
    else if @get('avatar_file_name')
      "#{ConsiderIt.public_root}/system/avatars/#{@id}/#{size}/#{@get('avatar_file_name')}"
    else
      "#{ConsiderIt.public_root}/system/default_avatar/#{size}_default-profile-pic.png"

  set_meta_data : (data) ->
    @meta = data

  is_meta_data_loaded : -> 
    !!@meta