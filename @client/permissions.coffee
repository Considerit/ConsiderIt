############################################################
###################### PERMISSIONS #########################
#
# We support two different methods of handling permissions.
#    1. Use the AccessControlled mixinAccess for putting a 
#       barrier on a url/Page.
#    2. For finer grained control, like for whether to show 
#       a button, use the permissions API (permit and 
#       recourse) as needed.
#
# Unfortunately we have to replicate server logic for some
# permissions checks. We try to keep these checks in this 
# file and in:
#       @server/permissions.rb 
# on the server, to manage this unfortunate circumstance. 
# If you're changing the logic in one place, you may need 
# to do so in the other as well. However, not all server 
# logic needs to be here and vice versa.
#

####
# Failure cases ENUM
# This needs to be synchronized with server (see @server/permissions.rb)
# Failure cases should be less than 0.
Permission = 
  PERMITTED: 1
  DISABLED : -1  # no one can take this action
  UNVERIFIED_EMAIL : -2 # can take action once email is verified 
  NOT_LOGGED_IN : -3 # not sure if action can be taken
  INSUFFICIENT_PRIVILEGES: -4 # we know this user can't do this



#######################
## Permission Definitions

# permit accepts an action parameter and a list of relevant objects
# for checking whether that action is permitted.
# 
# It returns a value from Permission indicating the result of the 
# permission check.
permit = (action) ->
  current_user = fetch '/current_user'

  switch action
    when 'create proposal'
      subdomain = fetch '/subdomain'

      return Permission.NOT_LOGGED_IN if !current_user.logged_in
      if !current_user.is_admin && !matchEmail(subdomain.roles.proposer)
        return Permission.INSUFFICIENT_PRIVILEGES 

    when 'update proposal', 'delete proposal'
      proposal = fetch arguments[1]
      if !current_user.is_admin && !matchEmail(proposal.roles.editor)
        return Permission.INSUFFICIENT_PRIVILEGES

    when 'publish opinion'
      proposal = fetch arguments[1]
      return Permission.DISABLED if !proposal.active
      return Permission.NOT_LOGGED_IN if !current_user.logged_in

      if !current_user.is_admin && !matchSomeRole(proposal.roles, ['editor', 'writer', 'opiner'])
        return Permission.INSUFFICIENT_PRIVILEGES 

    when 'update opinion'
      proposal = fetch arguments[1]
      opinion = fetch arguments[2]

      return Permission.INSUFFICIENT_PRIVILEGES if opinion.user != fetch('/current_user').user
        

    when 'create point'
      proposal = fetch arguments[1]
      return Permission.DISABLED if !proposal.active
      if !current_user.is_admin && !matchSomeRole(proposal.roles, ['editor', 'writer'])
        if !current_user.logged_in
          return Permission.NOT_LOGGED_IN  
        else 
          return Permission.INSUFFICIENT_PRIVILEGES 

    when 'update point'
      # Is an author allowed to edit a point after someone else has included it?
      point = fetch arguments[1]
      if !current_user.is_admin && point.user != fetch('/current_user').user
        return Permission.INSUFFICIENT_PRIVILEGES

    when 'delete point'
      point = fetch arguments[1]
      if !current_user.is_admin
        if point.user != fetch('/current_user').user
          return Permission.INSUFFICIENT_PRIVILEGES

        # Allow the point author to delete this point before it is published.
        # After it gets published, however, it can influence other people, so the author shouldn't be able to delete.
        # They can just remove it from their list if they don't believe it anymore. 
        if point.includers.length > 1 || (point.includers.length == 1 && point.includers[0] != current_user.user)
          return Permission.DISABLED

    when 'create comment'
      proposal = fetch arguments[1]
      return Permission.DISABLED if !proposal.active
      return Permission.NOT_LOGGED_IN if !current_user.logged_in 

      if !current_user.is_admin && !matchSomeRole(proposal.roles, ['editor', 'writer', 'commenter'])
        return Permission.INSUFFICIENT_PRIVILEGES 

    when 'update comment'
      comment = fetch arguments[1]
      if !current_user.is_admin && comment.user != fetch('/current_user').user
        return Permission.INSUFFICIENT_PRIVILEGES

    when 'request factcheck'
      proposal = fetch arguments[1]
      return Permission.DISABLED if !proposal.assessment_enabled || !proposal.active
      return Permission.NOT_LOGGED_IN if !current_user.logged_in 

  return Permission.PERMITTED

matchEmail = (permission_list) -> 
  user = fetch '/current_user'
  return true if '*' in permission_list
  return true if user.key in permission_list
  for email_or_key in permission_list
    if email_or_key.indexOf('*') > -1
      allowed_domain = email_or_key.split('@')[1]
      return true if user.email.split('@')[1] == allowed_domain
  return false

matchSomeRole = (roles, accepted_roles) ->
  for role in accepted_roles
    return true if matchEmail(roles[role])
  return false

####
# AccessControlled
#
# Mixin that implements a check for whether this user can access
# this Page (a component that this is mixed into). 
#
# The server has to respond with
# a keyed object w/ access_denied set for the component's key 
# for this mixin to be useful.
#
# Note that the component needs to explicitly call the accessGranted method
# in its render function. With something like:
#     return SPAN(null) if !@accessGranted()
#
AccessControlled = 
  accessGranted: -> 
    current_user = fetch '/current_user'

    ####
    # HACK: Clear out statebus if current_user changed. See comment below.
    local_but_not_component_unique = fetch "local-#{@page.key}"
    access_attrs = ['verified', 'logged_in', 'email']
    if local_but_not_component_unique._last_current_user && @data().access_denied 
      reduced_user = _.map access_attrs, (attr) -> current_user[attr] 
      for el,idx in reduced_user
        if el != local_but_not_component_unique._last_current_user[idx]
          delete @data().access_denied
          arest.serverFetch @page.key
          break
    ####


    if @data().access_denied && @data().access_denied < 0
      # Let's recover, depending on the recourse the server dictates
      switch @data().access_denied

        when Permission.INSUFFICIENT_PRIVILEGES
          window.app_router.navigate("/", {trigger: true})

        when Permission.NOT_LOGGED_IN
          @root.auth_mode = 'login'
          @root.auth_reason = 'Access this page'
          save @root

        when Permission.UNVERIFIED_EMAIL
          @root.auth_mode = 'verify'
          @root.auth_reason = 'Access this page'
          save @root
          current_user.trying_to = 'send_verification_token'
          save current_user


      #######
      # Hack! The server will return access_denied on the page, e.g.: 
      # 
      #   { key: '/page/dashboard/moderate', access_denied: 'login required' }
      # 
      # Here's a problem: 
      # What happens if the user logs in? Or if they verify their email?
      # We will need to refetch that page on the server so we can proceed 
      # with the proper data and without the access denied error.
      #
      # My solution here is to store relevant values of /current_user the last time
      # an access denied error was registered. Then everytime one of those attributes
      # changes (i.e. when the user might be able to access), we'll issue a server
      # fetch on the page.
      #
      local_but_not_component_unique._last_current_user = _.map access_attrs, (attr) -> current_user[attr] 
      save local_but_not_component_unique
      #
      # This hack will be unnecessary by having a server that pushes out changes to 
      # subscribed keys. In that world, the server logs a dependency for a client 
      # on an access-controlled resource. If the client ever gains the proper 
      # authorization, the server can just push down the data.

    return !@data().access_denied || @data().access_denied > 0


#######################
## Exports

window.AccessControlled = AccessControlled
window.permit = permit
window.Permission = Permission




