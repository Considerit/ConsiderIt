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
    return null if !@attributes.roles_mask?

    all_roles = ConsiderIt.User.available_roles

    user_roles = []
    me = this
    for element, idx in all_roles
      if me.attributes.roles_mask & Math.pow(2, idx) != 0
        user_roles.push element

    user_roles

  has_role : (role) ->
    _.indexOf(@roles(), role) >= 0


    #Roles.new(self, self.class.valid_roles.reject { |r| ( (@attributes.roles_mask || 0) & Math.pow(2, all_roles.index(r))).zero? })
