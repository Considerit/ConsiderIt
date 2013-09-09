@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->
  class Entities.User extends App.Entities.Model
    name : 'user'
    follows : {}
    defaults: 
      bio : ''
    fetched : false
  
    @available_roles : ['superadmin', 'admin', 'analyst', 'moderator', 'manager', 'evaluator', 'developer']

    url : ->
      Routes.user_path( @attributes.id )

    parse : (data) ->
      details = 'proposals' of data

      if details
        data.proposals = data.proposals.concat(_.values(data.referenced_proposals))
        App.vent.trigger 'proposals:fetched', data.proposals
        App.vent.trigger 'positions:fetched', (p.position for p in data.positions)
        App.vent.trigger 'points:fetched', (p.point for p in data.points.concat(_.values(data.referenced_points)))        
        App.vent.trigger 'comments:fetched', (c.comment for c in data.comments)
        @setInfluencedUsers data.influenced_users, data.influenced_users_by_point
        @fetched = true
      else
        data

    setInfluencedUsers : (all, by_point) ->
      @influenced_users = _.keys all
      @influenced_users_by_point = by_point

    getInfluencedUsers : ->
      [@influenced_users, @influenced_users_by_point]


      # :influenced_users => influenced_users,
      # :influenced_users_by_point => influenced_users_by_point      

    isFetched : -> @fetched

    joinedAt : ->
      created_at = @get('created_at')
      if created_at
        joined_at = created_at.substring(0, created_at.indexOf('T'))      
      else
        null
        
    ### AUTH ###
    hasRole : (role) -> _.indexOf(@roles(), role) >= 0
    updateRole : (roles_mask) -> @set 'roles_mask', roles_mask

    isAdmin : -> @hasRole('admin') || @hasRole('superadmin')
    isModerator : -> @isAdmin() || @hasRole('moderator')
    isAnalyst : -> @isAdmin() || @hasRole('analyst')
    isEvaluator : -> @isAdmin() || @hasRole('evaluator')
    isManager : -> @isAdmin() || @hasRole('manager')

    permissions : ->
      is_admin: @isAdmin()
      is_analyst: @isAnalyst()
      is_evaluator: @isEvaluator()
      is_manager: @isManager()
      is_moderator: @isModerator()

    roleList: -> @roles().join(', ')

    roles : ->

      if !@my_roles?
        return [] if !@attributes.roles_mask? || @attributes.roles_mask == 0

        all_roles = Entities.User.available_roles

        user_roles = []
        me = this
        for element, idx in all_roles
          if (me.attributes.roles_mask & Math.pow(2, idx)) > 0
            user_roles.push element

        @my_roles = user_roles
      @my_roles

    getTags : ->
      if tags = @get('tags')
        tags.split(';')
      else
        []

    ### Relations ###
    getProposals : ->
      if !@proposals 
        @proposals = App.request 'proposals:get:user', @id
      @proposals

    getPoints : ->
      if !@points
        @points = App.request 'points:get:user', @id
      @points

    getPositions : ->
      if !@positions
        @positions = App.request 'positions:get:user', @id
      @positions

    getComments : ->
      if !@comments
        @comments = App.request 'comments:get:user', @id
      @comments

    firstName : ->
      @get('name').split(' ')[0]

  class Entities.OperatingUser extends Entities.User
    ##### Follows #####
    setFollows : (follows) ->
      follows = ( f.follow for f in follows )
      @follows = {}
      for f in follows
        @follows[f.followable_type] = {} if !(f.followable_type of @follows)
        @follows[f.followable_type][f.followable_id] = f
      
    isFollowing : (followable_type, followable_id) ->
      if @isLoggedIn() && followable_type of @follows && followable_id of @follows[followable_type] && @follows[followable_type][followable_id].follow == true
        return @follows[followable_type][followable_id] 
      else
        false
        
    setFollowing : (follow) ->
      @follows[follow.followable_type] = {} if !_.has(@follows, follow.followable_type)
      @follows[follow.followable_type][follow.followable_id] = follow

    # unfollow : (followable_type, followable_id) ->
    #   follow = @follows[followable_type][followable_id] if followable_type of @follows && if followable_id of @follows[followable_type]
    #   follow.explicit = true
    #   follow.follow = false

    unfollowAll : ->
      for fgroup in _.values(@follows)
        for follow in _.values(fgroup)
          follow.explicit = true
          follow.follow = false

    isPersisted : ->
      'id' of @attributes

    #TODO: this method is technically incorrect...having a user id does not mean
    # that the user is logged in, only in the limited auth scenario where this
    # method is being used to detect whether a user has been created or not...
    # need to update this so there is an authoritative indicator from the server
    isLoggedIn : ->
      'id' of @attributes

    authMethod : ->
      attrs = @attributes
      auth_attrs = [ ['google_uid', 'google'], ['facebook_uid', 'facebook'], ['twitter_uid', 'twitter']]
      for auth in auth_attrs
        return auth[1] if auth[0] of attrs && attrs[auth[0]]? && attrs[auth[0]].length > 0
      return 'email'


  class Entities.Users extends Entities.Collection

    initialize : (options = {}) ->
      super options

    model: (attrs, options) ->
      if attrs.id? && 'operating_users' of options && attrs.id in options.operating_users
        new Entities.OperatingUser attrs, options
      else
        new Entities.User attrs, options





  #### USERS APP INTERFACE #####
  API = 
    all_users : null

    createUsers : (users, operating_users = []) ->
      users.push { id: -1, name: 'Anonymous'}
      @all_users = new Entities.Users users,  
        operating_users : operating_users

    updateUsers : (data) ->
      #TODO: double check this doesn't overwrite existing model data
      @all_users.set data, 
        remove : false

    getUsers : ->
      @all_users

    getUser : (user_id) ->
      user = @all_users.get user_id
      if !user
        user = new Entities.User {name : '<removed>'}
      user

    getAvatar : (user, size = 'small', fname = null) ->
      if fname?
        url = "#{ConsiderIt.public_root}/system/avatars/#{user.id}/#{size}/#{fname}"
      else if user.get 'avatar_file_name'
        url = "#{ConsiderIt.public_root}/system/avatars/#{user.id}/#{size}/#{user.get('avatar_file_name')}"
      else
        url = "#{ConsiderIt.public_root}/system/default_avatar/#{size}_default-profile-pic.png"
      url

    addUser : (params) ->
      @users.add params

  App.reqres.setHandler "user", (user_id) ->
    API.getUser user_id

  App.reqres.setHandler 'users', ->
    API.getUsers()

  App.reqres.setHandler 'users:update', (data) ->
    API.updateUsers data

  App.reqres.setHandler "user:avatar", (user, size = 'small', fname = null) ->
    API.getAvatar user, size, fname

  App.reqres.setHandler "user:current:avatar", (size = 'small', fname = null) ->
    current_user = App.request 'user:current'
    API.getAvatar current_user, size, fname

  App.reqres.setHandler 'users:add', (params) ->
    API.addUser params


  App.on 'initialize:before', ->
    current_user = ConsiderIt.current_user
    limited_user = ConsiderIt.limited_user_id

    API.createUsers ConsiderIt.users, [current_user, limited_user]


  #### AUTH APP INTERFACE ######

  AUTH_API = 
    current_user : null
    fixed_user : null

    get_current_user : ->
      @current_user

    get_fixed_user : ->
      @fixed_user

    set_current_user : (user_id) ->
      @current_user = App.request 'user', user_id
      if !(@current_user instanceof Entities.OperatingUser)
        @current_user.__proto__ = Entities.OperatingUser.prototype
      @current_user

    set_fixed_user : (user_data) ->
      if id of user_data.user     
        @fixed_user = App.request 'user', user_data.user.id
        @fixed_user.set user_data.user
        @fixed_user.setFollows user_data.follows if 'follows' of user_data
      else
        @fixed_user = App.request 'users:add', {email: user_data.user.email}      

      @fixed_user

    clear_current_user : ->
      @current_user = new App.Entities.OperatingUser {}

    clear_fixed_user : ->
      @fixed_user = null

    fixed_user_exists : ->
      !!@fixed_user

    update_current_user : (user_data) ->
      user_id = user_data.user.id

      AUTH_API.set_current_user user_id if @current_user.id != user_id

      current_user = @current_user

      current_user.set user_data.user
      current_user.setFollows user_data.follows if 'follows' of user_data

      if current_user.get 'b64_thumbnail'
        $('head').append("<style>#avatar-#{current_user.id}{background-image:url('#{current_user.get('b64_thumbnail')}');}</style>")

      App.vent.trigger 'user:updated'


    current_user_logged_in : ->
      current_user = App.request 'user:current'
      current_user && current_user.isPersisted()

    paperworkCompleted : ->
      current_user = App.request 'user:current'
      current_user.get 'registration_complete'





    
  App.reqres.setHandler 'user:current', ->
    AUTH_API.get_current_user()

  # App.reqres.setHandler "user:current:set", (user) ->
  #   AUTH_API.set_current_user user

  App.reqres.setHandler "user:current:clear", ->
    AUTH_API.clear_current_user()

  App.reqres.setHandler "user:current:update", (user_data) ->
    AUTH_API.update_current_user user_data

  App.reqres.setHandler "user:current:logged_in?", ->
    AUTH_API.current_user_logged_in()

  App.reqres.setHandler "user:fixed", ->
    AUTH_API.get_fixed_user()

  App.reqres.setHandler "user:fixed:exists", ->
    AUTH_API.fixed_user_exists()

  App.reqres.setHandler "user:fixed:clear", ->
    AUTH_API.clear_fixed_user()

  App.reqres.setHandler "user:paperwork_completed", ->
    AUTH_API.paperworkCompleted()

  App.reqres.setHandler "auth:can_moderate", ->
    current_user = AUTH_API.get_current_user()
    current_user && current_user.isModerator() && App.request("tenant:get").get('enable_moderation')

  App.reqres.setHandler "auth:can_assess", ->
    current_user = AUTH_API.get_current_user()
    current_user && current_user.isEvaluator() && App.request("tenant:get").get('assessment_enabled')

  App.reqres.setHandler "auth:can_create_proposal", ->
    current_user = AUTH_API.get_current_user()
    current_user && ( current_user.isManager() || App.request("tenant:get").get('enable_user_conversations') )

  App.reqres.setHandler "auth:can_edit_proposal", (proposal) ->
    current_user = AUTH_API.get_current_user() 
    current_user && ( current_user.id == proposal.get('user_id') || current_user.isManager() )   

  App.on 'initialize:before', ->

    if ConsiderIt.current_user_data
      AUTH_API.set_current_user ConsiderIt.current_user
      AUTH_API.update_current_user ConsiderIt.current_user_data
    else
      AUTH_API.clear_current_user()

    if ConsiderIt.limited_user_data
      AUTH_API.set_fixed_user { user : ConsiderIt.limited_user_data, follows : ConsiderIt.limited_user_follows }
    
    _.extend ConsiderIt,
      current_user_data : null
      limited_user_id : null
      limited_user_follows : null
      limited_user_email : null


